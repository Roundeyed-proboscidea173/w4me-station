(module
  (memory 1)

  (func $zero (result i64)
    (local $scratch i64)
    (local $initial i64)
    local.get $scratch
    local.set $initial
    i64.const 0x1122334455667788
    local.set $scratch
    local.get $initial)

  (func $one (param $value i64) (result i64)
    (local $scratch i64)
    local.get $scratch
    i64.eqz
    if
    else
      unreachable
    end
    i64.const 0x7766554433221100
    local.set $scratch
    local.get $value)

  (func $two (param $left i32) (param $right i64) (result i64)
    local.get $left
    i64.extend_i32_u
    i64.const 32
    i64.shl
    local.get $right
    i64.xor)

  (func $many
    (param $base i32)
    (param $word i32)
    (param $wide i64)
    (param $single f32)
    (param $double f64)
    (local $scratch i64)

    local.get $base
    local.get $word
    i32.store

    local.get $base
    i32.const 8
    i32.add
    local.get $wide
    i64.store

    local.get $base
    i32.const 16
    i32.add
    local.get $single
    f32.store

    local.get $base
    i32.const 24
    i32.add
    local.get $double
    f64.store

    local.get $base
    i32.const 32
    i32.add
    local.get $scratch
    i64.store

    i64.const 0x7f6e5d4c3b2a1908
    local.set $scratch)

  (func $recurse
    (param $depth i32)
    (param $seed i64)
    (result i64)
    (local $scratch i64)

    local.get $scratch
    i64.eqz
    if
    else
      unreachable
    end
    i64.const 0x1020304050607080
    local.set $scratch

    local.get $depth
    i32.eqz
    if (result i64)
      local.get $seed
    else
      local.get $depth
      i32.const 1
      i32.sub
      local.get $seed
      i64.const 1
      i64.add
      call $recurse
    end)

  (func (export "update")
    i32.const 0
    call $zero
    i64.store

    i32.const 8
    call $zero
    i64.store

    i32.const 16
    i64.const 0x8877665544332211
    call $one
    i64.store

    i32.const 24
    i32.const 0x89abcdef
    i64.const 0x0123456789abcdef
    call $two
    i64.store

    i32.const 64
    i32.const 0x80000001
    i64.const 0x8877665544332211
    i32.const 0x7fc12345
    f32.reinterpret_i32
    i64.const 0xfff8123456789abc
    f64.reinterpret_i64
    call $many

    i32.const 112
    i32.const 0x7ffffffe
    i64.const 0x0123456789abcdef
    i32.const 0x80000000
    f32.reinterpret_i32
    i64.const 1
    f64.reinterpret_i64
    call $many

    i32.const 160
    i32.const 3
    i64.const 0x1011121314151617
    call $recurse
    i64.store

    i32.const 168
    i32.const 4
    i64.const 0xf0e0d0c0b0a0908
    call $recurse
    i64.store)
)
