"use strict";

function requireOne(text, pattern, label) {
  const rows = [...text.matchAll(pattern)];
  if (rows.length !== 1) throw new Error(`${label} must appear exactly once`);
  return rows[0];
}

function parseToolchainIdentity(output) {
  if (!output || typeof output !== "object") throw new Error("toolchain output is missing");
  const { elixir, mix, hex } = output;
  if (![elixir, mix, hex].every((value) => typeof value === "string" && value.length > 0)) {
    throw new Error("toolchain command output is missing");
  }

  const elixirRuntimeMajor = requireOne(elixir, /^Erlang\/OTP ([0-9]+) \[/gm, "Elixir runtime OTP major")[1];
  const elixirVersion = requireOne(elixir, /^Elixir ([0-9]+\.[0-9]+\.[0-9]+) \(compiled with Erlang\/OTP ([0-9]+)\)$/gm,
    "Elixir version");
  if (elixirVersion[2] !== elixirRuntimeMajor) throw new Error("Elixir runtime OTP major is inconsistent");

  const mixRuntimeMajor = requireOne(mix, /^Erlang\/OTP ([0-9]+) \[/gm, "Mix runtime OTP major")[1];
  const mixVersion = requireOne(mix, /^Mix ([0-9]+\.[0-9]+\.[0-9]+) \(compiled with Erlang\/OTP ([0-9]+)\)$/gm,
    "Mix version");
  if (mixVersion[2] !== mixRuntimeMajor || mixRuntimeMajor !== elixirRuntimeMajor) {
    throw new Error("Mix runtime OTP major is inconsistent");
  }

  const hexVersion = requireOne(hex, /^Hex:\s*([^\s]+)\s*$/gm, "Hex version")[1];
  const hexElixirVersion = requireOne(hex, /^Elixir:\s*([^\s]+)\s*$/gm, "Hex runtime Elixir version")[1];
  const hexOtp = requireOne(hex, /^OTP:\s*([^\s]+)\s*$/gm, "Hex runtime OTP patch")[1];
  if (elixirVersion[1] !== "1.18.4" || elixirRuntimeMajor !== "27" || mixVersion[1] !== "1.18.4" ||
      hexVersion !== "2.6.0" || hexElixirVersion !== "1.18.4" || hexOtp !== "27.3.4.13") {
    throw new Error("installed Elixir/Mix/Hex runtime identity differs from D-35");
  }
  return {
    elixirVersion: elixirVersion[1],
    otpMajor: elixirRuntimeMajor,
    mixVersion: mixVersion[1],
    hexVersion,
    hexOtp,
  };
}

module.exports = { parseToolchainIdentity };
