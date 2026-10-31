inputs:
{
  wlib,
  pkgs,
  ...
}:
{
  imports = [ wlib.wrapperModules.neovim ];
  specs.general = with pkgs.vimPlugins; [
    # plugins which are loaded at startup ...
    conform-nvim
    friendly-snippets
    nvim-lint
    nvim-lspconfig
    nvim-treesitter
    nvim-treesitter-textobjects
    nvim-treesitter.withAllGrammars
    snacks-nvim
    tokyonight-nvim
    conform-nvim
    mini-nvim
  ];
  runtimePkgs = with pkgs; [
    # lsps, formatters, etc...

    # for Nix
    nixd
    nixfmt

    # Lua
    lua-language-server
    stylua

    # python
    basedpyright
    ruff

    # just
    just-lsp

    # general
    lazygit
    tree-sitter
  ];
  settings.config_directory = ./nvim;

  # hosts
  hosts.python3.nvim-host.enable = true;
  hosts.node.nvim-host.enable = true;
  hosts.ruby.nvim-host.enable = true;
}
