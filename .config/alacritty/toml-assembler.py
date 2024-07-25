import toml


def merge(paths):
    merged = {}

    for p in paths:
        with open(p, "r") as f:
            merged.update(toml.load(f))
    return merged


def save(conf, out_path):
    with open(out_path, "w") as f:
        toml.dump(conf, f)


out_path = "./alacritty.toml"

paths = [
    "./configs/basic.toml",
    "./configs/keybindings.toml",
    "./themes/catppuccin-macchiato.toml",
]

save(merge(paths), out_path)
