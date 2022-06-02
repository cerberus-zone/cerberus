package app

import (
	wasmkeeper "github.com/CosmWasm/wasmd/x/wasm/keeper"
)

const (
	DefaultCerberusInstanceCost uint64 = 60_000
	DefaultCerberusCompileCost uint64 = 100
)

func CerberusGasRegisterConfig() wasmkeeper.WasmGasRegisterConfig {
	gasConfig := wasmkeeper.DefaultGasRegisterConfig()
	gasConfig.InstanceCost = DefaultCerberusInstanceCost
	gasConfig.CompileCost = DefaultCerberusCompileCost

	return gasConfig
}

func NewCerberusWasmGasRegister() wasmkeeper.WasmGasRegister {
	return wasmkeeper.NewWasmGasRegister(CerberusGasRegisterConfig())
}