## Declaration order

Member declaration order:
1. `private`
2. `protected`
3. `package`
4. `public`
5. `export`

## Attributes

- Visibility modifiers (and static) in C++ syntax
    - Not required for public-only structs (PODs)
- Function attributes after brackets
- Use `in` instead of `const ref`

## Casing

- Non-public member variables: `m + PascalCase`
- Non-public static member variables: `s + PascalCase`
- Non-public module variables: `p + PascalCase`

- Classes, Structs, Interfaces, Unions: `PascalCase`
- Aliases: Dependent on type
- Constants: camelCase

Everything else: camelCase