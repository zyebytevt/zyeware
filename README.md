# ZyeWare Game Engine [![License](https://img.shields.io/github/license/zyebytevt/zyeware.svg)](https://github.com/zyebytevt/zyeware/blob/main/LICENSE.txt)

<p align="center">
    <img src="core.zpk/textures/engine-logo.png" width="600" alt="ZyeWare Logo">
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

## Can I create games with it?

If you can stomach it, sure. LGPL even allows you to create closed-source games with it, if your heart so desires.