def crp [] {
  let now = (date now)
  let year_part = ($now | format date "%Y")
  let month_part = ($now | format date  "%m")
  let day_part = ($now | format date "%d")
  let hour_part = ($now | format date "%I")
  let minute_part = ($now | format date "%M")
  let second_part = ($now | format date "%S")
  let meridiem = ($now | format date "%p")
  let neon_green = (ansi "#66ff00")
  let light_blue = (ansi "#7dd3fc")
  let indigo = (ansi "#a78bfa")
  let purple = (ansi "#9D00FF")
  let light_green = (ansi "#86efac")
  let reset = (ansi reset)
  $"($light_blue)($year_part)($reset)($indigo)-($reset)($light_blue)($month_part)($reset)($indigo)-($reset)($light_blue)($day_part)($reset) ($indigo)($hour_part)($reset)($neon_green):($reset)($indigo)($minute_part)($reset)($neon_green):($reset)($indigo)($second_part)($reset) ($purple)($meridiem)($reset) 🐡"
}

$env.EDITOR = 'vim'
$env.PROMPT_COMMAND_RIGHT = { || crp }
$env.config.show_banner = false

$env.config.abbreviations = {
    g: "~/.cargo/bin/giant-spellbook"
    pyup: "bash -i -c 'source ~/venv/bin/activate ; ~/.cargo/bin/nu'"
}
