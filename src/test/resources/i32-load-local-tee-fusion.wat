(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\78\56\34\12\ef\cd\ab\89")

  ;; Cross the production compact threshold before the focused sequence so
  ;; the same pair is exercised in both the outer and compact executors.
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

  (func (export "update") (local $first i32) (local $second i32)
    call $warm

    i32.const 512
    i32.const 256
    i32.load
    local.tee $first
    i32.const 260
    i32.load
    local.tee $second
    i32.add
    i32.store

    i32.const 516
    local.get $first
    local.get $second
    i32.xor
    i32.store)

  (func (export "trap_load") (local $sink i32)
    call $warm
    i32.const 65535
    i32.load
    local.tee $sink
    drop))
