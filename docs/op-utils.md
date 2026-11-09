# 1Password item helper

Use `op_get_item` to print a 1Password item as JavaScript Object Notation (JSON) without depending on this repository's Nix configuration.

## Requirements

You need:

- The Z shell (`zsh`)
- The 1Password command-line interface (`op`)
- Access to the 1Password account and vault that contain the item
- An authenticated `op` session

Install and authenticate the 1Password command-line interface using your organization's approved setup. The helper uses your local `op` session and does not contain or distribute credentials.

## Install without Nix

1. Copy [`home/op_utils.zsh`](../home/op_utils.zsh) to a location in your home directory, such as `~/.op_utils.zsh`.
2. Add this line to `~/.zshrc`:

   ```zsh
   source "$HOME/.op_utils.zsh"
   ```

3. Open a new Z shell, or source the helper in the current shell:

   ```zsh
   source "$HOME/.op_utils.zsh"
   ```

## Fetch an item

Call `op_get_item` with an item name or identifier (ID). Pass a vault or account when you need to select one explicitly. The helper prints the item returned by `op` to standard output and returns a nonzero status if the command fails.

```zsh
op_get_item "ITEM_NAME" --vault "VAULT_NAME" --account "ACCOUNT_NAME"
op_get_item "ITEM_ID" --account "ACCOUNT_NAME"
```

Replace `ITEM_NAME`, `ITEM_ID`, `VAULT_NAME`, and `ACCOUNT_NAME` with values available to your 1Password account. The vault and account options are optional when your `op` session has the right defaults.

The output format defaults to JSON. You can also pass a format accepted by `op item get`:

```zsh
op_get_item "ITEM_NAME" --format json
```

The helper prints the complete item. It does not extract a field or export a value as an environment variable. Treat the output as sensitive because it may contain passwords, tokens, or other credentials.

## Use with Home Manager

If you manage your Z shell with Home Manager, place `op_utils.zsh` in your configuration's `home/` directory, then add this mapping to a Home Manager module:

```nix
home.file.".op_utils.zsh".source = ./op_utils.zsh;
```

Source the managed file from `programs.zsh.initContent`:

```nix
programs.zsh.initContent = ''
  [[ -f "$HOME/.op_utils.zsh" ]] && source "$HOME/.op_utils.zsh"
'';
```

Each team member must configure their own 1Password access. Do not put item contents, passwords, or tokens in the shared repository.
