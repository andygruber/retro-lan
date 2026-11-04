// laninfo: info page and download server for a LAN party.
//
// Content (site.yml, pages/*.md, games/*.md, assets/) lives in a separate
// directory and is re-read on every request. Downloads are served straight
// from a second directory with range support, so interrupted downloads resume.
package main

import (
	"bytes"
	"crypto/sha256"
	"embed"
	"encoding/hex"
	"flag"
	"fmt"
	"html/template"
	"io"
	"io/fs"
	"log"
	"mime"
	"net"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	qrcode "github.com/skip2/go-qrcode"
	"github.com/yuin/goldmark"
)

//go:embed web
var webFS embed.FS

type App struct {
	contentDir   string
	downloadsDir string
	md           goldmark.Markdown
	tmpl         map[string]*template.Template
	version      string
}

type pageData struct {
	Site             *Site
	Nav              []*Page
	Active           string
	PageTitle        string
	Version          string
	AccentStyle      template.CSS
	HasCustomCSS     bool
	CustomCSSVersion string
	Errors           []string

	Body      template.HTML
	Page      *Page
	Games     []*Game
	Game      *Game
	Platforms []string
	Files     []FileEntry
	TotalSize int64
	FilesErr  string
	Host      string
	Message   string
}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func main() {
	addr := flag.String("addr", envOr("LANINFO_ADDR", ":8080"), "listen address")
	content := flag.String("content", envOr("LANINFO_CONTENT", "/data/content"), "content directory")
	downloads := flag.String("downloads", envOr("LANINFO_DOWNLOADS", "/data/downloads"), "downloads directory")
	health := flag.Bool("healthcheck", false, "check that the server on -addr answers, then exit")
	flag.Parse()

	if *health {
		os.Exit(healthcheck(*addr))
	}

	app, err := newApp(*content, *downloads)
	if err != nil {
		log.Fatal(err)
	}

	srv := &http.Server{
		Addr:              *addr,
		Handler:           logRequests(app.routes()),
		ReadHeaderTimeout: 15 * time.Second,
		IdleTimeout:       2 * time.Minute,
		// no WriteTimeout: downloads of several GB take a while
	}
	log.Printf("laninfo listening on %s (content %s, downloads %s)", *addr, *content, *downloads)
	log.Fatal(srv.ListenAndServe())
}

func healthcheck(addr string) int {
	_, port, err := net.SplitHostPort(addr)
	if err != nil {
		port = "8080"
	}
	c := http.Client{Timeout: 3 * time.Second}
	resp, err := c.Get("http://127.0.0.1:" + port + "/healthz")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return 1
	}
	return 0
}

func newApp(contentDir, downloadsDir string) (*App, error) {
	a := &App{contentDir: contentDir, downloadsDir: downloadsDir, md: newMarkdown(), tmpl: map[string]*template.Template{}}
	for _, name := range []string{"home", "games", "game", "downloads", "page", "error"} {
		t, err := template.New("").Funcs(templateFuncs).ParseFS(webFS, "web/templates/layout.html", "web/templates/"+name+".html")
		if err != nil {
			return nil, fmt.Errorf("template %s: %w", name, err)
		}
		a.tmpl[name] = t
	}
	// cache-busting version from the embedded static files
	h := sha256.New()
	fs.WalkDir(webFS, "web/static", func(p string, d fs.DirEntry, err error) error {
		if err == nil && !d.IsDir() {
			b, _ := webFS.ReadFile(p)
			h.Write(b)
		}
		return nil
	})
	a.version = hex.EncodeToString(h.Sum(nil))[:10]
	return a, nil
}

func (a *App) routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", a.handleHome)
	mux.HandleFunc("GET /games", a.handleGames)
	mux.HandleFunc("GET /games/{$}", redirect("/games"))
	mux.HandleFunc("GET /games/{slug}", a.handleGame)
	mux.HandleFunc("GET /p/{slug}", a.handlePage)
	mux.HandleFunc("GET /downloads", a.handleDownloads)
	mux.HandleFunc("GET /files/{path...}", a.handleFile)
	mux.HandleFunc("GET /assets/{path...}", a.handleAsset)
	mux.HandleFunc("GET /custom.css", a.handleCustomCSS)
	mux.HandleFunc("GET /qr.png", a.handleQR)
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) { io.WriteString(w, "ok\n") })

	static, _ := fs.Sub(webFS, "web/static")
	fileServer := http.StripPrefix("/static/", http.FileServerFS(static))
	mux.Handle("GET /static/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Query().Get("v") != "" {
			w.Header().Set("Cache-Control", "public, max-age=86400")
		}
		fileServer.ServeHTTP(w, r)
	}))
	mux.HandleFunc("/", a.handleNotFound)
	return mux
}

func redirect(to string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) { http.Redirect(w, r, to, http.StatusMovedPermanently) }
}

// ---------------------------------------------------------------- rendering

func (a *App) data(c *ctx, r *http.Request, active, title string) *pageData {
	d := &pageData{Site: c.site, Active: active, PageTitle: title, Version: a.version, Errors: c.errs, Host: r.Host}
	for _, p := range c.pages {
		if p.Nav == nil || *p.Nav {
			d.Nav = append(d.Nav, p)
		}
	}
	if validColor(strings.TrimSpace(c.site.Accent)) {
		d.AccentStyle = template.CSS("--accent: " + strings.TrimSpace(c.site.Accent))
	}
	if st, err := os.Stat(filepath.Join(a.contentDir, "custom.css")); err == nil {
		d.HasCustomCSS = true
		d.CustomCSSVersion = strconv.FormatInt(st.ModTime().Unix(), 36)
	}
	return d
}

func (a *App) render(w http.ResponseWriter, name string, d *pageData, status int) {
	var buf bytes.Buffer
	if err := a.tmpl[name].ExecuteTemplate(&buf, "layout", d); err != nil {
		log.Printf("template %s: %v", name, err)
		http.Error(w, "template error: "+err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-cache")
	w.WriteHeader(status)
	buf.WriteTo(w)
}

func (a *App) notFound(w http.ResponseWriter, r *http.Request, c *ctx, msg string) {
	if c == nil {
		c = a.load(r)
	}
	d := a.data(c, r, "", "Not found")
	d.Message = msg
	a.render(w, "error", d, http.StatusNotFound)
}

// ---------------------------------------------------------------- handlers

func (a *App) handleNotFound(w http.ResponseWriter, r *http.Request) {
	a.notFound(w, r, nil, "There is nothing at "+r.URL.Path+".")
}

func (a *App) handleHome(w http.ResponseWriter, r *http.Request) {
	c := a.load(r)
	d := a.data(c, r, "home", "")
	if c.home != nil {
		d.Body = c.home.Body
	}
	games, errs := a.loadGames(c.ex)
	d.Games = games
	d.Errors = append(d.Errors, errs...)
	a.render(w, "home", d, http.StatusOK)
}

func (a *App) handleGames(w http.ResponseWriter, r *http.Request) {
	c := a.load(r)
	d := a.data(c, r, "games", "Games")
	games, errs := a.loadGames(c.ex)
	d.Games = games
	d.Errors = append(d.Errors, errs...)
	seen := map[string]bool{}
	for _, g := range games {
		for _, p := range g.Platforms {
			if !seen[strings.ToLower(p)] {
				seen[strings.ToLower(p)] = true
				d.Platforms = append(d.Platforms, p)
			}
		}
	}
	a.render(w, "games", d, http.StatusOK)
}

func (a *App) handleGame(w http.ResponseWriter, r *http.Request) {
	c := a.load(r)
	slug := r.PathValue("slug")
	games, errs := a.loadGames(c.ex)
	for _, g := range games {
		if g.Slug == slug {
			d := a.data(c, r, "games", g.Title)
			d.Game = g
			d.Errors = append(d.Errors, errs...)
			a.render(w, "game", d, http.StatusOK)
			return
		}
	}
	a.notFound(w, r, c, "No game called “"+slug+"”.")
}

func (a *App) handlePage(w http.ResponseWriter, r *http.Request) {
	c := a.load(r)
	slug := r.PathValue("slug")
	if slug == "index" {
		http.Redirect(w, r, "/", http.StatusFound)
		return
	}
	for _, p := range c.pages {
		if p.Slug == slug {
			d := a.data(c, r, p.Slug, p.Title)
			d.Page = p
			a.render(w, "page", d, http.StatusOK)
			return
		}
	}
	a.notFound(w, r, c, "No page called “"+slug+"”.")
}

func (a *App) handleDownloads(w http.ResponseWriter, r *http.Request) {
	c := a.load(r)
	d := a.data(c, r, "downloads", "Downloads")
	games, errs := a.loadGames(c.ex)
	d.Errors = append(d.Errors, errs...)

	byFile := map[string][]*Game{}
	for _, g := range games {
		for _, dl := range g.Downloads {
			key := strings.TrimPrefix(path.Clean("/"+filepath.ToSlash(dl.File)), "/")
			byFile[key] = append(byFile[key], g)
			if !dl.Exists {
				d.Errors = append(d.Errors, fmt.Sprintf("games/%s.md: download %q not found in the downloads folder", g.Slug, dl.File))
			}
		}
	}
	files, err := a.listFiles()
	if err != nil {
		d.FilesErr = err.Error()
	}
	for _, f := range files {
		f.Games = byFile[f.Path]
		if len(f.Games) == 0 && !c.site.showAllFiles() {
			continue
		}
		d.Files = append(d.Files, f)
		d.TotalSize += f.Size
	}
	a.render(w, "downloads", d, http.StatusOK)
}

func (a *App) handleFile(w http.ResponseWriter, r *http.Request) {
	full, ok := safeJoin(a.downloadsDir, r.PathValue("path"))
	if !ok {
		http.NotFound(w, r)
		return
	}
	f, err := os.Open(full)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	defer f.Close()
	st, err := f.Stat()
	if err != nil || !st.Mode().IsRegular() {
		http.NotFound(w, r)
		return
	}
	name := filepath.Base(full)
	w.Header().Set("Content-Disposition", mime.FormatMediaType("attachment", map[string]string{"filename": name}))
	if ct := mime.TypeByExtension(filepath.Ext(name)); ct == "" {
		w.Header().Set("Content-Type", "application/octet-stream") // avoid content sniffing reads
	}
	http.ServeContent(w, r, name, st.ModTime(), f)
}

func (a *App) handleAsset(w http.ResponseWriter, r *http.Request) {
	full, ok := safeJoin(filepath.Join(a.contentDir, "assets"), r.PathValue("path"))
	if !ok {
		http.NotFound(w, r)
		return
	}
	f, err := os.Open(full)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	defer f.Close()
	st, err := f.Stat()
	if err != nil || !st.Mode().IsRegular() {
		http.NotFound(w, r)
		return
	}
	w.Header().Set("Cache-Control", "no-cache")
	http.ServeContent(w, r, st.Name(), st.ModTime(), f)
}

func (a *App) handleCustomCSS(w http.ResponseWriter, r *http.Request) {
	p := filepath.Join(a.contentDir, "custom.css")
	if _, err := os.Stat(p); err != nil {
		http.NotFound(w, r)
		return
	}
	w.Header().Set("Cache-Control", "no-cache")
	http.ServeFile(w, r, p)
}

// handleQR renders the QR code of a home page card (qr: wifi, or any text/URL).
func (a *App) handleQR(w http.ResponseWriter, r *http.Request) {
	c := a.load(r)
	i, err := strconv.Atoi(r.URL.Query().Get("card"))
	if err != nil || i < 0 || i >= len(c.site.Cards) || c.site.Cards[i].QR == "" {
		http.NotFound(w, r)
		return
	}
	text := c.site.Cards[i].QR
	if strings.EqualFold(text, "wifi") {
		text = wifiQRText(c.ex)
		if text == "" {
			http.NotFound(w, r)
			return
		}
	}
	png, err := qrcode.Encode(text, qrcode.Medium, 512)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "image/png")
	w.Header().Set("Cache-Control", "no-cache")
	w.Write(png)
}

func wifiQRText(v expander) string {
	ssid := v["wifi_ssid"]
	if ssid == "" {
		return ""
	}
	esc := strings.NewReplacer(`\`, `\\`, `;`, `\;`, `,`, `\,`, `:`, `\:`, `"`, `\"`).Replace
	sec := strings.ToUpper(strings.TrimSpace(v["wifi_security"]))
	switch sec {
	case "", "WPA2", "WPA3", "WPA/WPA2":
		sec = "WPA"
	case "NOPASS", "NONE", "OPEN":
		sec = "nopass"
	}
	s := "WIFI:T:" + sec + ";S:" + esc(ssid) + ";"
	if sec != "nopass" {
		s += "P:" + esc(v["wifi_password"]) + ";"
	}
	if h := strings.ToLower(v["wifi_hidden"]); h == "true" || h == "yes" || h == "1" {
		s += "H:true;"
	}
	return s + ";"
}

// ---------------------------------------------------------------- logging

type statusWriter struct {
	http.ResponseWriter
	status int
	bytes  int64
}

func (s *statusWriter) WriteHeader(code int) {
	if s.status == 0 {
		s.status = code
	}
	s.ResponseWriter.WriteHeader(code)
}

func (s *statusWriter) Write(b []byte) (int, error) {
	if s.status == 0 {
		s.status = http.StatusOK
	}
	n, err := s.ResponseWriter.Write(b)
	s.bytes += int64(n)
	return n, err
}

// ReadFrom keeps sendfile(2) working for big downloads.
func (s *statusWriter) ReadFrom(r io.Reader) (int64, error) {
	if s.status == 0 {
		s.status = http.StatusOK
	}
	var n int64
	var err error
	if rf, ok := s.ResponseWriter.(io.ReaderFrom); ok {
		n, err = rf.ReadFrom(r)
	} else {
		n, err = io.Copy(struct{ io.Writer }{s.ResponseWriter}, r)
	}
	s.bytes += n
	return n, err
}

func (s *statusWriter) Unwrap() http.ResponseWriter { return s.ResponseWriter }

func logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasPrefix(r.URL.Path, "/static/") || r.URL.Path == "/healthz" {
			next.ServeHTTP(w, r)
			return
		}
		start := time.Now()
		sw := &statusWriter{ResponseWriter: w}
		next.ServeHTTP(sw, r)
		ip, _, _ := net.SplitHostPort(r.RemoteAddr)
		extra := ""
		if strings.HasPrefix(r.URL.Path, "/files/") {
			extra = " " + humanSize(sw.bytes)
			if rg := r.Header.Get("Range"); rg != "" {
				extra += " range=" + rg
			}
		}
		log.Printf("%s %s %s %d %s%s", ip, r.Method, r.URL.Path, sw.status, time.Since(start).Round(time.Millisecond), extra)
	})
}
