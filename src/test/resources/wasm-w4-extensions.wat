(module
  (import "env" "memory" (memory 0 65536))
  (data $payload "W4ME")
  (global $phase (mut i32) (i32.const 0))

  (func (export "update")
    global.get $phase
    if
      i32.const 20036
      i32.const 0
      i32.const 0
      i32.const 0
      memory.init $payload
      i32.const 1
      i32.store

      i32.const 0
      i32.const 0
      i32.const 1
      memory.init $payload
      return
    end

    i32.const 20000
    i32.const 0
    i32.const 4
    memory.init $payload
    data.drop $payload

    i32.const 20004
    f32.const nan
    i32.trunc_sat_f32_s
    i32.store

    i32.const 20008
    f32.const -1e30
    i32.trunc_sat_f32_s
    i32.store

    i32.const 20012
    f64.const 1e100
    i32.trunc_sat_f64_u
    i32.store

    i32.const 20016
    f64.const -1e100
    i64.trunc_sat_f64_s
    i64.store

    i32.const 20024
    f64.const 1e100
    i64.trunc_sat_f64_u
    i64.store

    i32.const 20032
    i32.const 0
    memory.grow
    i32.store

    i32.const 1
    global.set $phase))
