# 🍃 MulleCA

#### 🍃 Animate objects in realtime

Animation in simple programs is often tied to the framerate. With CAAnimation
you get a little framework to tie animation to real time, which can make things
look smoother for the receiver.

This library is independent of any drawing library.


### You are here

```
  .-----------------------------------------.
  | MulleUIFoundation                       |
  '-----------------------------------------'
  .-----------------------------------------.
  | MulleUIControl                          |
  '-----------------------------------------'
  .-----------------. .---------------------.
  | MulleUIImage    | | MulleUICore         |
  '-----------------' '--------------.------.
  .--------------------------------. | glfw |
  | MulleGraphics                  | | X11  |
  '--------------------------------' '------'
  .-----------------. .============.
  | MulleCG         | | MulleCA    |
  '-----------------' '============'
  .--------------------------------.
  | mulle-layout                   |
  '--------------------------------'
```
