Procedural Textures Addon
=========================

An Addon for Godot 4.3 to design Procedural Textures for your Gaming Design needs.

Created by Esther Dalhuisen (wakeofluna).

Introduction
============

This Addon allows the user to use the Godot Visual Editor to string together various
patterns and filters in order to simply create stunning looking textures. These
textures are fully procedural which means they are calculated (once) at loadtime and
do not take up precious storage space in your dstribution package.

An example for a simple bricks texture:

![Bricks Design Example](docs/bricks_example.png?raw=true)

Internally, the procedural designs work by grabbing Godot Shader code for each node and stringing them together according to the design.


HOWTO
=====

Create a new design
-------------------
* Add a new Resource to your project called `ProceduralTextureDesign`
* Save the Resource

Note: there is currently an issue where the design is labelled "[unsaved]" when it has first been created. This does not go away until the design is saved, closed and reopened.


Close a design from the editor
------------------------------
* Middle-click on the design in the design list


Instantiate a texture from a design
-----------------------------------
* Create a new resource called `ProceduralTexture` (either a fresh resource or inline in a `Texture2D` property e.g. in a `StandardMaterial`.
* In the properties of the `ProceduralTexture`, load the desired design.
* Once the design has been selected, select the desired Output from the design.

Add your own Pattern/Filter
---------------------------
In order to correctly interoperate with the Shader Building framework, the Shader needs to meet the following demands:

* Be an unshaded canvas shader

  ```
  shader_type canvas_item;
  render_mode unshaded;
  ```

  Note that this does not mean that the generated texture will be unshaded. This just means that no lighting is used when generating the texture itself.

* Have a comment to indicate the name of the filter: 
  
  `// NAME:My Pattern Name`

* Have a function called `vec4 sample_xxx(vec2 uv)` for every sampler2D uniform input, where `xxx` must match the name of the uniform.

* Have a function called `process` which takes as arguments all the non-sampler2D uniforms to the shader.

* Optionally have a fragment function that calls the `process()` function so you can preview your shadercode using e.g. a `ShaderTexture`.

Your best bet is to look at one of the provided builtin shaders, such as the [Constant Color](addons/procedural_textures/shaders/pattern_constant_color.gdshader) pattern or the [Math](addons/procedural_textures/shaders/filter_math.gdshader) filter.

After adding a new Shader, you need to restart the Editor once so it is picked up by the Editor component. After that, you do not have to restart the Editor if you make changes to your Shader.

Build your Texture without using the Editor
-------------------------------------------

* Instantiate a `ShaderTexture` resource.
* In the shader slot, add for example a filter shader.
* The filter shader will have more shader input properties that can be filled in.
* Keep going filling in shader properties until you end up with a pattern that does not require any more inputs.