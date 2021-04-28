# Buffer Navigator

Display buffers as tree to quickly navigate between them.

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

TBD

The buffer navigator can be toggled by using either of these:

- <kbd>leader</kbd> + <kbd>b</kbd>
- `:BufferNavigatorToggle`

Inside the buffer tree the following mappings exists:

- <kbd>Return</kbd> or <kbd>o</kbd> - Switch to the selected buffer
- <kbd>s</kbd> - Like o, but opens in a split
- <kbd>v</kbd> - Like o, but opens in a vertical split
- <kbd>z</kbd> - Toggle zoom, which increases/decreases the width of the buffer window
- <kbd>x</kbd> - Close selected buffer or the whole selected tree

## Customization

TBD

```vim
let g:BufferNavigatorWinWidth = 40

highlight BufferNavigatorFile
highlight BufferNavigatorModifiedFile
highlight BufferNavigatorDir
```

## Documentation

You can view the full manual with `:help buffer-navigator`.
