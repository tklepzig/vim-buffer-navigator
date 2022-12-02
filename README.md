# Buffer Navigator

Display buffers as tree in a separate window. In it you can preview any buffer or switch directly to it.
Additionally, you can close a single buffer or all inside a directory tree.

![BufferNavigator Screenshot](https://github.com/tklepzig/vim-buffer-navigator/raw/master/assets/screenshot.jpg)

## Installation

### [Vundle](https://github.com/gmarik/Vundle.vim)

1.  Add the following configuration to your `.vimrc`.

        Plugin 'tklepzig/vim-buffer-navigator'

2.  Install with `:BundleInstall`.

### [NeoBundle](https://github.com/Shougo/neobundle.vim)

1.  Add the following configuration to your `.vimrc`.

        NeoBundle 'tklepzig/vim-buffer-navigator'

2.  Install with `:NeoBundleInstall`.

### [Plug](https://github.com/junegunn/vim-plug)

1.  Add the following configuration to your `.vimrc`.

        Plug 'tklepzig/vim-buffer-navigator'

2.  Install with `:PlugInstall`.

## Usage

The buffer navigator can be toggled by using either of these:

- <kbd>leader</kbd> + <kbd>b</kbd> (Can be disabled by setting `let g:BufferNavigatorMapKeys = 0`)
- `:BufferNavigatorToggle`

Inside the buffer tree the following mappings exists:

| Key               | Function                                                             |
| ----------------- | -------------------------------------------------------------------- |
| <kbd>o</kbd>      | Switch to selected buffer                                            |
| <kbd>Return</kbd> | Same as <kbd>o</kbd>                                                 |
| <kbd>s</kbd>      | Open selected buffer in split                                        |
| <kbd>v</kbd>      | Open selected buffer in vertical split                               |
| <kbd>p</kbd>      | Open buffer in preview mode (buffer navigator window stays open)     |
| <kbd>x</kbd>      | Close selected buffer or tree                                        |
| <kbd>z</kbd>      | Toggle zoom (increase width of buffer navigator window to max width) |
| <kbd>r</kbd>      | Refresh buffer tree                                                  |
| <kbd>m</kbd>      | Toggle mode between tree and MRU                                     |

## Documentation

You can view the full manual (including customization options) with `:help buffer-navigator`.

## Contribution

Have a feature request or found a bug? Open an issue at https://github.com/tklepzig/vim-buffer-navigator/issues.
