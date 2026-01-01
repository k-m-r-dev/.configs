{ pkgs, ... }:
{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()
      local act = wezterm.action

      -- Appearance
      config.color_scheme = 'Catppuccin Mocha'
      config.font = wezterm.font('MonaspiceNe Nerd Font', { weight = 'Medium' })
      config.font_size = 12.0
      config.window_background_opacity = 0.92
      config.macos_window_background_blur = 30
      config.window_decorations = 'RESIZE'
      config.window_padding = { left = 12, right = 12, top = 12, bottom = 8 }
      config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }

      -- Performance
      config.max_fps = 120
      config.front_end = 'WebGpu'

      -- Cursor
      config.default_cursor_style = 'BlinkingBar'
      config.cursor_blink_rate = 500

      -- Tab bar (retro = compact powerline style)
      config.use_fancy_tab_bar = false
      config.tab_max_width = 32

      -- General behavior
      config.default_prog = { '/bin/zsh', '-l' }
      config.window_close_confirmation = 'NeverPrompt'
      config.audible_bell = 'SystemBeep'
      config.scrollback_lines = 10000

      -- Leader key for modal operations
      config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1500 }

      -- Keybindings: Only add what differs from defaults
      -- Defaults already include: CMD+c/v, CMD+-/=/0, CMD+m/n, CMD+t/w, CMD+1-9
      config.keys = {
        -- Overrides/additions
        { key = 'Enter', mods = 'CMD', action = act.ToggleFullScreen },
        { key = 'Enter', mods = 'CMD|SHIFT', action = wezterm.action_callback(function(window, _) window:maximize() end) },
        { key = 'w', mods = 'CMD', action = act.CloseCurrentTab({ confirm = false }) },

        -- Tab nav (defaults use CMD+SHIFT+[/])
        { key = '[', mods = 'CMD', action = act.ActivateTabRelative(-1) },
        { key = ']', mods = 'CMD', action = act.ActivateTabRelative(1) },

        -- Pane splits
        { key = '\\', mods = 'CMD', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
        { key = '-', mods = 'CMD|SHIFT', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },

        -- Pane nav (hjkl style)
        { key = 'h', mods = 'CMD|SHIFT', action = act.ActivatePaneDirection('Left') },
        { key = 'j', mods = 'CMD|SHIFT', action = act.ActivatePaneDirection('Down') },
        { key = 'k', mods = 'CMD|SHIFT', action = act.ActivatePaneDirection('Up') },
        { key = 'l', mods = 'CMD|SHIFT', action = act.ActivatePaneDirection('Right') },

        -- Pane management
        { key = 'z', mods = 'CMD|SHIFT', action = act.TogglePaneZoomState },
        { key = 'x', mods = 'CMD', action = act.CloseCurrentPane({ confirm = false }) },
        { key = 's', mods = 'CMD|SHIFT', action = act.PaneSelect({ mode = 'SwapWithActive' }) },
        { key = 'p', mods = 'LEADER', action = act.ActivateKeyTable({ name = 'resize_pane', one_shot = false, timeout_milliseconds = 3000 }) },

        -- Half-page scroll
        { key = 'u', mods = 'CMD', action = act.ScrollByPage(-0.5) },
        { key = 'd', mods = 'CMD', action = act.ScrollByPage(0.5) },

        -- macOS text nav (essential for terminal)
        { key = 'LeftArrow', mods = 'OPT', action = act.SendString('\x1bb') },
        { key = 'RightArrow', mods = 'OPT', action = act.SendString('\x1bf') },
        { key = 'LeftArrow', mods = 'CMD', action = act.SendString('\x01') },
        { key = 'RightArrow', mods = 'CMD', action = act.SendString('\x05') },
        { key = 'Backspace', mods = 'OPT', action = act.SendString('\x17') },
        { key = 'Backspace', mods = 'CMD', action = act.SendString('\x15') },

        -- Workspaces
        { key = 'w', mods = 'LEADER', action = act.ShowLauncherArgs({ flags = 'WORKSPACES' }) },
      }

      -- Key table for pane resizing
      config.key_tables = {
        resize_pane = {
          { key = 'h', action = act.AdjustPaneSize({ 'Left', 2 }) },
          { key = 'j', action = act.AdjustPaneSize({ 'Down', 2 }) },
          { key = 'k', action = act.AdjustPaneSize({ 'Up', 2 }) },
          { key = 'l', action = act.AdjustPaneSize({ 'Right', 2 }) },
          { key = 'Escape', action = 'PopKeyTable' },
          { key = 'q', action = 'PopKeyTable' },
        },
      }

      -- CMD+click to open links
      config.mouse_bindings = {
        { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CMD', action = act.OpenLinkAtMouseCursor },
      }

      return config
    '';
  };
}
