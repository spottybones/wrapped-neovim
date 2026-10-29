inputs:
{
  config,
  wlib,
  lib,
  pkgs,
  options,
  ...
}:
{
  imports = [ wlib.wrapperModules.neovim ];

  # NOTE: see the tips and tricks section or the bottom of this file + flake inputs to understand this value
  options.nvim-lib.neovimPlugins = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf wlib.types.stringable;
    # Makes plugins autobuilt from our inputs available with
    # `config.nvim-lib.neovimPlugins.<name_without_prefix>`
    default = config.nvim-lib.pluginsFromPrefix "plugins-" inputs;
  };

  # choose a directory for your config.
  config.settings.config_directory = ./nvim;
  # you can also use an impure path!
  # config.settings.config_directory = lib.generators.mkLuaInline "vim.fn.stdpath('config')";
  # config.settings.config_directory = "/home/<USER>/.config/nvim";
  # If you do that, it will not be provisioned by nix, but it will have normal reload for quick edits!

  # If you want to install multiple neovim derivations via home.packages or environment.systemPackages
  # in order to prevent path collisions:

  # set this to true:
  config.settings.dont_link = true;

  # and make sure these dont share values:
  config.binName = "nvim";
  config.settings.aliases = [ ];

  # you can name these whatever you want.
  config.specs.nix = {
    data = null;
    runtimePkgs = with pkgs; [
      nixd
      nixfmt
    ];
  };
  # You can use the before and after fields to run them before or after other specs or spec of lists of specs
  config.specs.lua = {
    after = [ "general" ];
    lazy = true;
    data = with pkgs.vimPlugins; [
      lazydev-nvim
    ];
    runtimePkgs = with pkgs; [
      lua-language-server
      stylua
    ];
  };

  # set up Python
  config.specs.python = {
    after = [ "general" ];
    lazy = true;
    data = null;
    runtimePkgs = with pkgs; [
      basedpyright
    ];
  };

  # set up Just
  config.specs.just = {
    after = [ "general" ];
    lazy = true;
    data = null;
    runtimePkgs = with pkgs; [
      just-lsp
    ];
  };

  config.specs.general = {
    # this would ensure any config included from nix in here will be ran after any provided by the `lze` spec
    # If we provided any from within either spec, anyway
    # after = [ "lze" ];
    # note we didn't have to specify the `lze` specs name, because it was a top level spec
    runtimePkgs = with pkgs; [
      lazygit
      tree-sitter
    ];
    # this `lazy = true` definition will transfer to specs in the contained DAL, if there is one.
    # This is because the definition of lazy in `config.specMods` checks `parentSpec.lazy or false`
    # the submodule type for `config.specMods` gets `parentSpec` as a `specialArg`.
    # you can define options like this too!
    # lazy = true;
    # here we chose a DAL of plugins, but we can also pass a single plugin, or null
    # plugins are of type wlib.types.stringable
    data = with pkgs.vimPlugins; [
      mini-nvim

      # mini-ai
      # mini-align
      # mini-basics
      # mini-bracketed
      # mini-bufremove
      # mini-clue
      # mini-comment
      # mini-completion
      # mini-diff
      # mini-extra
      # mini-files
      # mini-git
      # mini-hipatterns
      # mini-icons
      # mini-indentscope
      # mini-jump
      # mini-jump2d
      # mini-keymap
      # mini-map
      # mini-misc
      # mini-move
      # mini-notify
      # mini-operators
      # mini-pairs
      # mini-pick
      # mini-sessions
      # mini-snippets
      # mini-starter
      # mini-statusline
      # mini-surround
      # mini-tabline
      # mini-trailspace
      # mini-visits

      tokyonight-nvim
      friendly-snippets
      nvim-treesitter
      nvim-treesitter-textobjects
      nvim-treesitter.withAllGrammars
      nvim-lint
      conform-nvim
      snacks-nvim
      nvim-lspconfig

      # nvim-surround
      # vim-startuptime
      # blink-cmp
      # blink-compat
      # cmp-cmdline
      # colorful-menu-nvim
      # lualine-nvim
      # gitsigns-nvim
      # which-key-nvim
      # fidget-nvim
      # treesitter + grammars
      # This is for if you only want some of the grammars
      # (nvim-treesitter.withPlugins (
      #   plugins: with plugins; [
      #     nix
      #     lua
      #   ]
      # ))
    ];
  };

  # These are from the tips and tricks section of the neovim wrapper docs!
  # https://nix-community.github.io/nix-wrapper-modules/neovim.html#tips-and-tricks
  # We could put these in another module and import them here instead!

  # This submodule modifies both levels of your specs
  config.specMods =
    {
      # When this module is ran in an inner list,
      # this will contain `config` of the parent spec
      parentSpec ? null,
      # and this will contain `options`
      # otherwise they will be `null`
      parentOpts ? null,
      parentName ? null,
      # and then config from this one, as normal
      config,
      # and the other module arguments.
      ...
    }:
    {
      # you could use this to change defaults for the specs
      # config.collateGrammars = lib.mkDefault (parentSpec.collateGrammars or false);
      # config.autoconfig = lib.mkDefault (parentSpec.autoconfig or false);
      # config.runtimeDeps = lib.mkDefault (parentSpec.runtimeDeps or false);
      # config.pluginDeps = lib.mkDefault (parentSpec.pluginDeps or false);
      # or something more interesting like:
      # add a runtimePkgs field to the specs themselves
      options.runtimePkgs = options.runtimePkgs // {
        description = ''
          A runtimePkgs spec field to put packages on the PATH
          If the spec is disabled, this value will not be included in the resulting neovim derivation
        '';
      };
      # You could do this too
      # config.before = lib.mkDefault [ "INIT_MAIN" ];
    };
  config.runtimePkgs = config.specCollect (acc: v: acc ++ (v.runtimePkgs or [ ])) [ ];

  # Inform our lua of which top level specs are enabled
  options.settings.cats = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf lib.types.bool;
    default = builtins.mapAttrs (_: v: v.enable) config.specs;
  };
  # build plugins from inputs set
  options.nvim-lib.pluginsFromPrefix = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default =
      prefix: inputs:
      lib.pipe inputs [
        builtins.attrNames
        (builtins.filter (s: lib.hasPrefix prefix s))
        (map (
          input:
          let
            name = lib.removePrefix prefix input;
          in
          {
            inherit name;
            value = config.nvim-lib.mkPlugin name inputs.${input};
          }
        ))
        builtins.listToAttrs
      ];
  };
}
