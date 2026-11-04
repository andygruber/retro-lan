package main

// Loading of the editable content: site.yml, pages/*.md and games/*.md.
// Everything is read again on every request, so edits show up on reload.

import (
	"errors"
	"fmt"
	"hash/fnv"
	"html/template"
	"io/fs"
	"net"
	"net/http"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

// ---------------------------------------------------------------- types

type Site struct {
	Title        string         `yaml:"title"`
	Tagline      string         `yaml:"tagline"`
	Accent       string         `yaml:"accent"`
	Footer       string         `yaml:"footer"`
	ShowAllFiles *bool          `yaml:"show_all_files"`
	Vars         map[string]any `yaml:"vars"`
	Cards        []Card         `yaml:"cards"`

	FooterHTML template.HTML `yaml:"-"`
}

type Card struct {
	Title string     `yaml:"title"`
	Icon  string     `yaml:"icon"`
	Text  string     `yaml:"text"`
	QR    string     `yaml:"qr"`
	Wide  bool       `yaml:"wide"`
	Items []CardItem `yaml:"items"`

	TextHTML template.HTML `yaml:"-"`
}

type CardItem struct {
	Label  string `yaml:"label"`
	Value  string `yaml:"value"`
	Link   string `yaml:"link"`
	Copy   bool   `yaml:"copy"`
	Secret bool   `yaml:"secret"`
	Mono   bool   `yaml:"mono"`
}

type Page struct {
	Slug  string `yaml:"-"`
	Title string `yaml:"title"`
	Order int    `yaml:"order"`
	Nav   *bool  `yaml:"nav"`
	Icon  string `yaml:"icon"`

	Body template.HTML `yaml:"-"`
}

type Game struct {
	Slug      string     `yaml:"-"`
	Title     string     `yaml:"title"`
	Short     string     `yaml:"short"`
	Subtitle  string     `yaml:"subtitle"`
	Summary   string     `yaml:"summary"`
	Genre     string     `yaml:"genre"`
	Year      string     `yaml:"year"`
	Players   string     `yaml:"players"`
	Platforms []string   `yaml:"platforms"`
	Tags      []string   `yaml:"tags"`
	Order     int        `yaml:"order"`
	Color     string     `yaml:"color"`
	Image     string     `yaml:"image"`
	Hidden    bool       `yaml:"hidden"`
	Downloads []Download `yaml:"downloads"`
	Servers   []Server   `yaml:"servers"`
	Links     []Link     `yaml:"links"`

	Body          template.HTML `yaml:"-"`
	TotalSize     int64         `yaml:"-"`
	ColorStyle    template.CSS  `yaml:"-"`
	ImageURL      string        `yaml:"-"`
	SearchText    string        `yaml:"-"`
	PlatformsAttr string        `yaml:"-"`
	MissingFiles  int           `yaml:"-"`
}

type Download struct {
	File     string `yaml:"file"`
	Label    string `yaml:"label"`
	Notes    string `yaml:"notes"`
	Platform string `yaml:"platform"`

	Name      string        `yaml:"-"`
	Size      int64         `yaml:"-"`
	Exists    bool          `yaml:"-"`
	URL       string        `yaml:"-"`
	NotesHTML template.HTML `yaml:"-"`
}

type Server struct {
	Name     string `yaml:"name"`
	Address  string `yaml:"address"`
	Protocol string `yaml:"protocol"`
	Join     string `yaml:"join"`
	Notes    string `yaml:"notes"`

	NotesHTML template.HTML `yaml:"-"`
}

type Link struct {
	Label string `yaml:"label"`
	URL   string `yaml:"url"`
}

type FileEntry struct {
	Path    string
	Name    string
	Dir     string
	URL     string
	Size    int64
	ModTime time.Time
	Games   []*Game
}

// ---------------------------------------------------------------- variables

// expander replaces {{name}} placeholders with variable values.
type expander map[string]string

var placeholderRe = regexp.MustCompile(`\{\{\s*([A-Za-z0-9_]+)\s*\}\}`)

func (e expander) expand(s string) string {
	if !strings.Contains(s, "{{") {
		return s
	}
	return placeholderRe.ReplaceAllStringFunc(s, func(m string) string {
		key := strings.ToLower(placeholderRe.FindStringSubmatch(m)[1])
		if v, ok := e[key]; ok {
			return v
		}
		return m // unknown: leave visible so the typo can be spotted
	})
}

func (e expander) list(in []string) []string {
	out := make([]string, 0, len(in))
	for _, s := range in {
		if s = strings.TrimSpace(e.expand(s)); s != "" {
			out = append(out, s)
		}
	}
	return out
}

// buildVars merges site.yml vars, LAN_* environment variables and the
// built-in ones (host, server_ip, site_title).
func buildVars(r *http.Request, s *Site) expander {
	v := expander{}
	for k, val := range s.Vars {
		if val == nil {
			v[strings.ToLower(k)] = ""
		} else {
			v[strings.ToLower(k)] = fmt.Sprint(val)
		}
	}
	for _, kv := range os.Environ() {
		k, val, ok := strings.Cut(kv, "=")
		if ok && strings.HasPrefix(k, "LAN_") && len(k) > 4 {
			v[strings.ToLower(k[4:])] = val
		}
	}
	host := r.Host
	hostname := host
	if h, _, err := net.SplitHostPort(host); err == nil {
		hostname = h
	}
	hostname = strings.Trim(hostname, "[]")
	v["host"] = host
	if strings.TrimSpace(v["server_ip"]) == "" {
		v["server_ip"] = hostname
	}
	if _, ok := v["site_title"]; !ok {
		v["site_title"] = s.Title
	}
	// one level of nesting: vars may reference other vars
	for k, val := range v {
		v[k] = v.expand(val)
	}
	return v
}

// ---------------------------------------------------------------- request context

type ctx struct {
	site  *Site
	ex    expander
	pages []*Page
	home  *Page
	errs  []string
}

func (a *App) load(r *http.Request) *ctx {
	c := &ctx{}
	site, err := a.loadSite()
	if err != nil {
		c.errs = append(c.errs, err.Error())
	}
	c.site = site
	c.ex = buildVars(r, site)
	a.expandSite(site, c.ex)
	c.pages, c.home, err = a.loadPages(c.ex)
	if err != nil {
		c.errs = append(c.errs, strings.Split(err.Error(), "\n")...)
	}
	return c
}

// ---------------------------------------------------------------- site.yml

func defaultSite() *Site { return &Site{Title: "LAN Party"} }

func (a *App) loadSite() (*Site, error) {
	var b []byte
	var err error
	for _, name := range []string{"site.yml", "site.yaml"} {
		b, err = os.ReadFile(filepath.Join(a.contentDir, name))
		if err == nil || !errors.Is(err, fs.ErrNotExist) {
			break
		}
	}
	if errors.Is(err, fs.ErrNotExist) {
		return defaultSite(), nil
	}
	if err != nil {
		return defaultSite(), fmt.Errorf("site.yml: %v", err)
	}
	s := &Site{}
	if err := yaml.Unmarshal(b, s); err != nil {
		return defaultSite(), fmt.Errorf("site.yml: %v", err)
	}
	if strings.TrimSpace(s.Title) == "" {
		s.Title = "LAN Party"
	}
	return s, nil
}

func (a *App) expandSite(s *Site, e expander) {
	s.Title = e.expand(s.Title)
	s.Tagline = e.expand(s.Tagline)
	s.Accent = e.expand(s.Accent)
	if s.Footer != "" {
		s.FooterHTML = a.inline(s.Footer, e)
	}
	for i := range s.Cards {
		c := &s.Cards[i]
		c.Title = e.expand(c.Title)
		c.QR = e.expand(c.QR)
		if strings.TrimSpace(c.Text) != "" {
			c.TextHTML = a.markdown(c.Text, e)
		}
		items := c.Items[:0]
		for _, it := range c.Items {
			it.Label = e.expand(it.Label)
			it.Value = e.expand(it.Value)
			it.Link = e.expand(it.Link)
			if strings.TrimSpace(it.Value) == "" && it.Link == "" {
				continue // hide empty rows, e.g. an unset variable
			}
			items = append(items, it)
		}
		c.Items = items
	}
}

func (s *Site) showAllFiles() bool { return s.ShowAllFiles == nil || *s.ShowAllFiles }

// ---------------------------------------------------------------- frontmatter

// splitFrontmatter splits "---\nyaml\n---\nbody" into its two parts.
func splitFrontmatter(b []byte) (fm, body string) {
	s := strings.TrimPrefix(string(b), "\ufeff")
	s = strings.ReplaceAll(s, "\r\n", "\n")
	if !strings.HasPrefix(s, "---\n") {
		return "", s
	}
	rest := s[4:]
	if strings.HasPrefix(rest, "---\n") || rest == "---" {
		return "", strings.TrimPrefix(rest, "---")
	}
	if i := strings.Index(rest, "\n---\n"); i >= 0 {
		return rest[:i], rest[i+5:]
	}
	if strings.HasSuffix(rest, "\n---") {
		return strings.TrimSuffix(rest, "\n---"), ""
	}
	return "", s
}

func readMarkdownFiles(dir string) ([]string, error) {
	files, err := filepath.Glob(filepath.Join(dir, "*.md"))
	if err != nil {
		return nil, err
	}
	out := files[:0]
	for _, f := range files {
		base := filepath.Base(f)
		if strings.HasPrefix(base, "_") || strings.HasPrefix(base, ".") {
			continue // _template.md and friends
		}
		out = append(out, f)
	}
	sort.Strings(out)
	return out, nil
}

func titleFromSlug(slug string) string {
	s := strings.NewReplacer("-", " ", "_", " ").Replace(slug)
	if s == "" {
		return slug
	}
	return strings.ToUpper(s[:1]) + s[1:]
}

// ---------------------------------------------------------------- pages

func (a *App) loadPages(e expander) (pages []*Page, home *Page, err error) {
	files, _ := readMarkdownFiles(filepath.Join(a.contentDir, "pages"))
	var errs []error
	for _, f := range files {
		slug := strings.TrimSuffix(filepath.Base(f), ".md")
		b, rerr := os.ReadFile(f)
		if rerr != nil {
			errs = append(errs, fmt.Errorf("pages/%s.md: %v", slug, rerr))
			continue
		}
		fm, body := splitFrontmatter(b)
		p := &Page{Slug: slug}
		if fm != "" {
			if yerr := yaml.Unmarshal([]byte(fm), p); yerr != nil {
				errs = append(errs, fmt.Errorf("pages/%s.md: %v", slug, yerr))
			}
		}
		if p.Title == "" {
			p.Title = titleFromSlug(slug)
		}
		p.Title = e.expand(p.Title)
		p.Body = a.markdown(body, e)
		if slug == "index" {
			home = p
			continue
		}
		pages = append(pages, p)
	}
	sort.SliceStable(pages, func(i, j int) bool {
		if pages[i].Order != pages[j].Order {
			return pages[i].Order < pages[j].Order
		}
		return strings.ToLower(pages[i].Title) < strings.ToLower(pages[j].Title)
	})
	return pages, home, errors.Join(errs...)
}

// ---------------------------------------------------------------- games

var gamePalette = []string{"#7c3aed", "#2563eb", "#0891b2", "#059669", "#d97706", "#dc2626", "#db2777", "#4f46e5"}

func (a *App) loadGames(e expander) ([]*Game, []string) {
	files, _ := readMarkdownFiles(filepath.Join(a.contentDir, "games"))
	var games []*Game
	var errs []string
	for _, f := range files {
		slug := strings.TrimSuffix(filepath.Base(f), ".md")
		b, err := os.ReadFile(f)
		if err != nil {
			errs = append(errs, fmt.Sprintf("games/%s.md: %v", slug, err))
			continue
		}
		fm, body := splitFrontmatter(b)
		g := &Game{}
		if fm != "" {
			if err := yaml.Unmarshal([]byte(fm), g); err != nil {
				errs = append(errs, fmt.Sprintf("games/%s.md: %v", slug, err))
			}
		}
		g.Slug = slug
		if g.Hidden {
			continue
		}
		a.prepareGame(g, body, e)
		games = append(games, g)
	}
	sort.SliceStable(games, func(i, j int) bool {
		if games[i].Order != games[j].Order {
			return games[i].Order < games[j].Order
		}
		return strings.ToLower(games[i].Title) < strings.ToLower(games[j].Title)
	})
	return games, errs
}

func (a *App) prepareGame(g *Game, body string, e expander) {
	if strings.TrimSpace(g.Title) == "" {
		g.Title = titleFromSlug(g.Slug)
	}
	g.Title = e.expand(g.Title)
	g.Short = e.expand(g.Short)
	if g.Short == "" {
		g.Short = initials(g.Title)
	}
	g.Subtitle = e.expand(g.Subtitle)
	g.Summary = e.expand(g.Summary)
	g.Genre = e.expand(g.Genre)
	g.Year = e.expand(g.Year)
	g.Players = e.expand(g.Players)
	g.Platforms = e.list(g.Platforms)
	g.Tags = e.list(g.Tags)

	for i := range g.Downloads {
		d := &g.Downloads[i]
		d.File = strings.TrimSpace(e.expand(d.File))
		d.Label = e.expand(d.Label)
		d.Platform = e.expand(d.Platform)
		d.Name = path.Base(filepath.ToSlash(d.File))
		if d.Notes != "" {
			d.NotesHTML = a.inline(d.Notes, e)
		}
		if full, ok := safeJoin(a.downloadsDir, d.File); ok && d.File != "" {
			if st, err := os.Stat(full); err == nil && st.Mode().IsRegular() {
				d.Exists = true
				d.Size = st.Size()
				d.URL = fileURL(d.File)
				g.TotalSize += d.Size
			}
		}
		if !d.Exists {
			g.MissingFiles++
		}
	}
	for i := range g.Servers {
		s := &g.Servers[i]
		s.Name = e.expand(s.Name)
		s.Address = e.expand(s.Address)
		s.Protocol = e.expand(s.Protocol)
		s.Join = e.expand(s.Join)
		if s.Notes != "" {
			s.NotesHTML = a.inline(s.Notes, e)
		}
	}
	for i := range g.Links {
		g.Links[i].Label = e.expand(g.Links[i].Label)
		g.Links[i].URL = e.expand(g.Links[i].URL)
		if g.Links[i].Label == "" {
			g.Links[i].Label = g.Links[i].URL
		}
	}

	color := strings.TrimSpace(e.expand(g.Color))
	if !validColor(color) {
		h := fnv.New32a()
		h.Write([]byte(g.Slug))
		color = gamePalette[int(h.Sum32())%len(gamePalette)]
	}
	g.ColorStyle = template.CSS("--game-color: " + color)

	if img := strings.TrimSpace(e.expand(g.Image)); img != "" {
		if strings.HasPrefix(img, "/") || strings.Contains(img, "://") {
			g.ImageURL = img
		} else {
			g.ImageURL = "/assets/" + escapePath(img)
		}
	}

	g.PlatformsAttr = strings.ToLower(strings.Join(g.Platforms, "|"))
	g.SearchText = strings.ToLower(strings.Join(append([]string{g.Title, g.Short, g.Subtitle, g.Genre, g.Summary, g.Year},
		append(g.Tags, g.Platforms...)...), " "))
	g.Body = a.markdown(body, e)
}

func initials(title string) string {
	var out []rune
	for _, w := range strings.Fields(title) {
		r := []rune(w)
		if len(r) == 0 {
			continue
		}
		if r[0] >= '0' && r[0] <= '9' {
			out = append(out, r...) // keep numbers like 2004 whole
		} else {
			out = append(out, []rune(strings.ToUpper(string(r[0])))...)
		}
		if len(out) >= 6 {
			break
		}
	}
	return string(out)
}

var colorRe = regexp.MustCompile(`^(#[0-9a-fA-F]{3,8}|[a-zA-Z]{3,20}|(rgb|rgba|hsl|hsla|oklch|oklab)\([0-9a-zA-Z.,%\s/+-]+\))$`)

func validColor(c string) bool { return c != "" && colorRe.MatchString(c) }

// ---------------------------------------------------------------- files

// safeJoin maps a relative URL/content path below root. Dot files and
// dot directories are refused.
func safeJoin(root, rel string) (string, bool) {
	clean := path.Clean("/" + filepath.ToSlash(rel))
	for _, seg := range strings.Split(clean, "/") {
		if strings.HasPrefix(seg, ".") {
			return "", false
		}
	}
	return filepath.Join(root, filepath.FromSlash(clean)), true
}

func escapePath(p string) string {
	segs := strings.Split(strings.TrimPrefix(path.Clean("/"+filepath.ToSlash(p)), "/"), "/")
	for i, s := range segs {
		segs[i] = url.PathEscape(s)
	}
	return strings.Join(segs, "/")
}

func fileURL(rel string) string { return "/files/" + escapePath(rel) }

func (a *App) listFiles() ([]FileEntry, error) {
	var out []FileEntry
	root := a.downloadsDir
	if _, err := os.Stat(root); err != nil {
		return nil, err
	}
	err := filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil // skip unreadable entries
		}
		if p != root && strings.HasPrefix(d.Name(), ".") {
			if d.IsDir() {
				return fs.SkipDir
			}
			return nil
		}
		if d.IsDir() {
			return nil
		}
		info, err := os.Stat(p) // follows symlinks
		if err != nil || !info.Mode().IsRegular() {
			return nil
		}
		rel, _ := filepath.Rel(root, p)
		rel = filepath.ToSlash(rel)
		dir := path.Dir(rel)
		if dir == "." {
			dir = ""
		}
		out = append(out, FileEntry{Path: rel, Name: path.Base(rel), Dir: dir, URL: fileURL(rel), Size: info.Size(), ModTime: info.ModTime()})
		return nil
	})
	sort.Slice(out, func(i, j int) bool { return strings.ToLower(out[i].Path) < strings.ToLower(out[j].Path) })
	return out, err
}
