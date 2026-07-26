(module
  (memory (export "memory") 1)

  (global $ne (export "ne") (mut i32) (i32.const 0))
  (global $lt-s (export "lt_s") (mut i32) (i32.const 0))
  (global $le-s (export "le_s") (mut i32) (i32.const 0))
  (global $le-u (export "le_u") (mut i32) (i32.const 0))
  (global $ge-s (export "ge_s") (mut i32) (i32.const 0))

  ;; Keep every exported probe above the production compact threshold without
  ;; changing the threshold or relying on an activation-policy experiment.
  (func $warm (local $index i32)
    (block $done
      (loop $again
        local.get $index
        i32.const 10000
        i32.ge_u
        br_if $done
        local.get $index
        i32.const 1
        i32.add
        local.set $index
        br $again)))

  (func (export "update")
    call $warm

    i32.const 256
    i32.const -2147483648
    i32.store

    i32.const 256
    i32.load
    i32.const 0
    i32.ne
    global.set $ne

    i32.const -2147483648
    i32.const 0
    i32.lt_s
    global.set $lt-s

    i32.const -1
    i32.const -1
    i32.le_s
    global.set $le-s

    i32.const 0
    i32.const -1
    i32.le_u
    global.set $le-u

    i32.const 0
    i32.const -1
    i32.ge_s
    global.set $ge-s)

  (func (export "trap_load") (local $sink i32)
    call $warm
    i32.const 0
    local.set $sink
    i32.const 1
    local.set $sink
    i32.const 65535
    i32.load
    local.set $sink)

  (func (export "trap_store") (local $sink i32)
    call $warm
    i32.const 0
    local.set $sink
    i32.const 1
    local.set $sink
    i32.const 65535
    i32.const 305419896
    i32.store))
