import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface CycleInfo { 'balance' : bigint, 'available' : bigint }
export type Error = { 'CommonError' : null } |
  { 'InternalError' : string } |
  { 'UnsupportedToken' : string } |
  { 'InsufficientFunds' : null };
export interface PositionIndex {
  'addPoolId' : ActorMethod<[string], Result>,
  'getCycleInfo' : ActorMethod<[], Result_2>,
  'getPools' : ActorMethod<[], Result_1>,
  'getUserPools' : ActorMethod<[string], Result_1>,
  'getVersion' : ActorMethod<[], string>,
  'removePoolId' : ActorMethod<[string], Result>,
  'removePoolIdWithoutCheck' : ActorMethod<[string], Result>,
  'updatePoolIds' : ActorMethod<[], undefined>,
}
export type Result = { 'ok' : boolean } |
  { 'err' : Error };
export type Result_1 = { 'ok' : Array<string> } |
  { 'err' : Error };
export type Result_2 = { 'ok' : CycleInfo } |
  { 'err' : Error };
export interface _SERVICE extends PositionIndex {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
