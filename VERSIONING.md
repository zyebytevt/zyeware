# ZyeWare versioning system

In general, we'll use a versioning system similar to [Semantic versioning](https://semver.org/):

MAJOR.MINOR.PATCH, which increment:
1. MAJOR version when we make incompatible public API changes
2. MINOR version when we add functionality in a backwards compatible manner
3. PATCH version when we make backwards compatible bug fixes

(Public API in this case is every piece of code that is reachable by the client application, in the case of D when the `public` modifier is applied)

## Version string

A small "v" should be prepended in front of the actual version number.

If appropriate, a pre-release version name is appended with a hyphen (-), usually "alpha", "beta" and "rc".

Finally, appended to this is the 7 character long git commit id with a plus (+) sign, for easy identification where a build
came from.

Which would result in this hypothetical version string:
`v0.1.2-alpha+fe3f237`

Major version zero (0.y.z) is, as defined by SemVer, used for initial development and incompatible changes may happen anytime.

With the introduction of this versioning schema, we'll arbitrarily start at 0.3.0, because 3 is
a nice number.

## Querying the version number

It should always be possible to get the version number from `ZyeWare.Version`