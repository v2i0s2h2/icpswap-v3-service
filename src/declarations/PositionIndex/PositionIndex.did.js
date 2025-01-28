export const idlFactory = ({ IDL }) => {
  const Error = IDL.Variant({
    'CommonError' : IDL.Null,
    'InternalError' : IDL.Text,
    'UnsupportedToken' : IDL.Text,
    'InsufficientFunds' : IDL.Null,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Bool, 'err' : Error });
  const CycleInfo = IDL.Record({ 'balance' : IDL.Nat, 'available' : IDL.Nat });
  const Result_2 = IDL.Variant({ 'ok' : CycleInfo, 'err' : Error });
  const Result_1 = IDL.Variant({ 'ok' : IDL.Vec(IDL.Text), 'err' : Error });
  const PositionIndex = IDL.Service({
    'addPoolId' : IDL.Func([IDL.Text], [Result], []),
    'getCycleInfo' : IDL.Func([], [Result_2], []),
    'getPools' : IDL.Func([], [Result_1], ['query']),
    'getUserPools' : IDL.Func([IDL.Text], [Result_1], ['query']),
    'getVersion' : IDL.Func([], [IDL.Text], ['query']),
    'removePoolId' : IDL.Func([IDL.Text], [Result], []),
    'removePoolIdWithoutCheck' : IDL.Func([IDL.Text], [Result], []),
    'updatePoolIds' : IDL.Func([], [], []),
  });
  return PositionIndex;
};
export const init = ({ IDL }) => { return [IDL.Principal]; };
