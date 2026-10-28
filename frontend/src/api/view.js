import { aptos, fn } from "../config";

export async function view(mod, name, args = []) {
  const res = await aptos.view({
    payload: { function: fn(mod, name), functionArguments: args },
  });
  return res[0];
}