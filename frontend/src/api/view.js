import { aptos, fn } from "../config";

export async function view(mod, name, args = []) {
  return aptos.view({
    payload: { function: fn(mod, name), functionArguments: args },
  });
}
