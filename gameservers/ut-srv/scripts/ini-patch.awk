# Merges override files into an Unreal Engine ini file.
#
#   awk -f ini-patch.awk overrides.ini [more-overrides.ini ...] UnrealTournament.ini > new.ini
#
# The last file is the ini to patch, all files before it are overrides.
# Override syntax, per [Section]:
#
#   Key=Value    set Key. Several lines with the same Key in one section
#                replace the whole list (e.g. ServerActors, GameConfig).
#   +Key=Value   add the line if the section doesn't have it yet
#   -Key=Value   remove that exact line
#
# Sections and keys are matched case-insensitively like the engine does.
# Sections that don't exist yet are appended. Lines starting with ; or #
# are comments. A later override file wins over an earlier one.

function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

# Emit the pending set/add lines of section s that were not written yet
function flush(s,    i, k) {
  if (s == "" || !(s in nops)) return
  for (i = 1; i <= nops[s]; i++) {
    k = s SUBSEP i
    if (optype[k] == "=" && !((s, lc(opkey[k])) in emitted)) {
      emit_set(s, lc(opkey[k]))
    } else if (optype[k] == "+" && !((s, lc(opkey[k]) "=" opval[k]) in present)) {
      print opkey[k] "=" opval[k]
      present[s, lc(opkey[k]) "=" opval[k]] = 1
    }
  }
}

function emit_set(s, key,    i, k) {
  for (i = 1; i <= nops[s]; i++) {
    k = s SUBSEP i
    if (optype[k] == "=" && lc(opkey[k]) == key) print opkey[k] "=" opval[k]
  }
  emitted[s, key] = 1
}

function lc(s) { return tolower(s) }

function header(line) { return line ~ /^\[[^\]]+\][ \t]*$/ }

BEGIN { last = ARGV[ARGC - 1] }

{ sub(/\r$/, "") }

# ---- override files --------------------------------------------------------
FILENAME != last {
  line = trim($0)
  if (line == "" || line ~ /^[;#]/) next
  if (header(line)) {
    sec = lc(trim(line))
    if (!(sec in nops)) { nops[sec] = 0; secname[sec] = trim(line); order[++nsecs] = sec }
    next
  }
  if (sec == "" || index(line, "=") == 0) next
  type = "="
  if (line ~ /^[+-]/) { type = substr(line, 1, 1); line = substr(line, 2) }
  key = trim(substr(line, 1, index(line, "=") - 1))
  val = trim(substr(line, index(line, "=") + 1))
  # a set in a later file replaces the earlier set of the same key
  if (type == "=" && !((sec, lc(key)) in fileset && fileset[sec, lc(key)] == FILENAME)) {
    for (i = 1; i <= nops[sec]; i++)
      if (optype[sec, i] == "=" && lc(opkey[sec, i]) == lc(key)) optype[sec, i] = "x"
    fileset[sec, lc(key)] = FILENAME
  }
  if (type == "-") removed[sec, lc(key) "=" val] = 1
  n = ++nops[sec]
  optype[sec, n] = type; opkey[sec, n] = key; opval[sec, n] = val
  next
}

# ---- the ini ---------------------------------------------------------------
header($0) {
  flush(cur)
  for (i = 1; i <= blanks; i++) print ""
  blanks = 0
  cur = lc(trim($0)); seen[cur] = 1
  print; next
}

/^[ \t]*$/ { blanks++; next }

{
  for (i = 1; i <= blanks; i++) print ""
  blanks = 0
  if (cur != "" && index($0, "=") > 0 && $0 !~ /^[ \t]*[;#]/) {
    key = lc(trim(substr($0, 1, index($0, "=") - 1)))
    val = trim(substr($0, index($0, "=") + 1))
    if ((cur, key "=" val) in removed) next
    if (fileset[cur, key] != "") {
      if (!((cur, key) in emitted)) emit_set(cur, key)
      next
    }
    present[cur, key "=" val] = 1
  }
  print
}

END {
  flush(cur)
  for (i = 1; i <= blanks; i++) print ""
  for (j = 1; j <= nsecs; j++) {
    s = order[j]
    if (s in seen) continue
    print ""; print secname[s]
    flush(s)
  }
}
