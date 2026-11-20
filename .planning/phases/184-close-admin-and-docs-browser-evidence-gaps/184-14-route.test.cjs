"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { parseToolchainIdentity } = require("./184-14-route.cjs");

test("toolchain accepts OTP patch only from the Hex runtime field", () => {
  const output = {
    elixir: "Erlang/OTP 27 [erts-15.2.7.9] [source] [64-bit] [smp:2:2] [ds:2:2:10] [async-threads:1] [jit]\n\nElixir 1.18.4 (compiled with Erlang/OTP 27)\n",
    mix: "Erlang/OTP 27 [erts-15.2.7.9] [source] [64-bit] [smp:2:2] [ds:2:2:10] [async-threads:1] [jit]\n\nMix 1.18.4 (compiled with Erlang/OTP 27)\n",
    hex: "Hex:    2.6.0\nElixir: 1.18.4\nOTP:    27.3.4.13\n\nBuilt with: Elixir 1.18.0 and OTP 27.3.4.9\n",
  };

  assert.deepEqual(parseToolchainIdentity(output), {
    elixirVersion: "1.18.4",
    otpMajor: "27",
    mixVersion: "1.18.4",
    hexVersion: "2.6.0",
    hexOtp: "27.3.4.13",
  });
});
