# ZyeWare Game Engine
[![License](https://img.shields.io/github/license/zyebytevt/zyeware?style=plastic)](https://github.com/zyebytevt/zyeware/blob/main/LICENSE.txt) [![Open issues](https://img.shields.io/github/issues/zyebytevt/zyeware?style=plastic)](https://github.com/zyebytevt/zyeware/issues) [![Last commit](https://img.shields.io/github/last-commit/zyebytevt/zyeware?style=plastic)](https://github.com/zyebytevt/zyeware/commits/main)

<p align="center">
    <img src="res/core-package/textures/engine-logo.png" width="600" alt="ZyeWare Logo">
</p>

## Introduction

ZyeWare is a multi-platform, general purpose 2D and 3D game engine (mainly focused on 2D though). Not much more to say quite yet.

I'm mainly developing this engine on stream over on [my channel](https://twitch.tv/zyebytevt)!

## History

Initial work started back in 2019 when developing a game engine for a physics engine assignment. This was then rewritten in 2021 to the current structure, until it was forgotten about. Beginning with 2023, I've picked it up again, rebranded, and am trying to finally mature it enough as to be able to create simple (or maybe even more sophisticated) games with it.

A very important resource, especially for the early stages of the engine rewrite, has been [Hazel](https://github.com/TheCherno/Hazel) from Cherno! He's really cool, you should check him out!

## What can it do?

Not much currently. It supports a Virtual File System with high moddability, various rendering functionalities (where 2D is rendered with batching), audio of course, and has a quite well integrated Entity Component System structure on top of it. Available backends are currently OpenGL (with SDL) and OpenAL.

## Games created with ZyeWare

Not yet. I'll start listing them as soon as there are, though.

## Contributions?

If you want to contribute, that would be really cool! Please just be aware of various pitfalls:

- Methods declared in DI files must be implemented in a separate file *exactly* in the order they were declared in. Otherwise very strange linking issues occur.
- I try to take readability of code very seriously, so while still trying to be performant, please perfer clear and easy to understand code instead of black magic.

### How to build (or create a game)

Following these steps should give you a working development setup:

- Clone this repository somewhere under the name `zyeware`, and afterwards register it as a local package with `dub add-local zyeware/ "1.0.0"`
- Clone https://github.com/zyebytevt/zpklink somewhere as `zpklink`, and register it with `dub add-local zpklink/ "1.0.0"`
- Fetch the necessary dependencies. For now, this should only be SDL2, OpenGL and OpenAL. How you get those libraries depends on your operating system.
- Now you can either create a new project with `zyeware` as a DUB dependency, or you can clone https://github.com/zyebytevt/zyeware-sandbox for a base and lots of examples on how to do stuff.

## Can I create games with it?

If you can stomach it, sure. LGPL even allows you to create closed-source games with it, if your heart so desires.