#!/bin/bash
#----------------- test rollback ------------------------
allBalanceBefore=""
allBalanceAfter=""
positionsBefore=""
positionsAfter=""
ticksBefore=""
ticksAfter=""
userPositionsBefore=""
userPositionsAfter=""
metadataBefore=""
metadataAfter=""
tokenStateBefore=""
tokenStateAfter=""
recordBefore=""
recordAfter=""
function checkRollback() 
{
    if [ "$positionsBefore" = "$positionsAfter" ]; then
      echo "\033[32m positions are same. \033[0m"
    else
      echo "\033[31m positions are not same. \033[0m"
    fi

    if [ "$ticksBefore" = "$ticksAfter" ]; then
      echo "\033[32m ticks are same. \033[0m"
    else
      echo "\033[31m ticks are not same. \033[0m"
    fi

    if [ "$userPositionsBefore" = "$userPositionsAfter" ]; then
      echo "\033[32m user positions are same. \033[0m"
    else
      echo "\033[31m user positions are not same. \033[0m"
    fi

    if [ "$allBalanceBefore" = "$allBalanceAfter" ]; then
      echo "\033[32m user balance are same. \033[0m"
    else
      echo "\033[31m user balance are not same. \033[0m"
    fi

    if [ "$tokenStateBefore" = "$tokenStateAfter" ]; then
      echo "\033[32m token state are same. \033[0m"
    else
      echo "\033[31m token state are not same. \033[0m"
    fi

    if [ "$recordBefore" = "$recordAfter" ]; then
      echo "\033[32m record are same. \033[0m"
    else
      echo "\033[31m record are not same. \033[0m"
    fi

    echo $metadataBefore
    echo $metadataAfter
}
function recordBefore() 
{
    allBalanceBefore=`dfx canister call $poolId allTokenBalance "(0: nat, 100: nat)"`
    positionsBefore=`dfx canister call $poolId getPositions "(0: nat, 100: nat)"`
    ticksBefore=`dfx canister call $poolId getTicks "(0: nat, 100: nat)"`
    userPositionsBefore=`dfx canister call $poolId getUserPositions "(0: nat, 100: nat)"`
    metadataBefore=`dfx canister call $poolId metadata`
    tokenStateBefore=`dfx canister call $poolId getTokenAmountState`
    recordBefore=`dfx canister call $poolId getSwapRecordState`
}
function recordAfter() 
{
    allBalanceAfter=`dfx canister call $poolId allTokenBalance "(0: nat, 100: nat)"`
    positionsAfter=`dfx canister call $poolId getPositions "(0: nat, 100: nat)"`
    ticksAfter=`dfx canister call $poolId getTicks "(0: nat, 100: nat)"`
    userPositionsAfter=`dfx canister call $poolId getUserPositions "(0: nat, 100: nat)"`
    metadataAfter=`dfx canister call $poolId metadata`
    tokenStateAfter=`dfx canister call $poolId getTokenAmountState`
    recordAfter=`dfx canister call $poolId getSwapRecordState`
}
#----------------- test rollback ------------------------

#----------------- test withdraw mistransfer balance ------------------------
function withdraw_mistransfer()
{

    dfx canister call TrustedCanisterManager addCanister "(principal \"$(dfx canister id ICRC2)\")"
    result=`dfx canister call TrustedCanisterManager getCanisters`
    echo "getCanisters: $result"

    dfx canister call ICRC2 icrc1_transfer "(record {from_subaccount = null; to = record {owner = principal \"$poolId\"; subaccount = opt blob \"$subaccount\";}; amount = 100000000:nat; fee = opt $TRANS_FEE; memo = null; created_at_time = null;})"

    result=`dfx canister call $poolId withdrawMistransferBalance "(record {address = \"$(dfx canister id ICRC2)\"; standard = \"ICRC1\";})"`
    echo "withdrawMistransferBalance: $result"

    dfx canister call TrustedCanisterManager deleteCanister "(principal \"$(dfx canister id ICRC2)\")"
    result=`dfx canister call TrustedCanisterManager getCanisters`
    echo "getCanisters: $result"

    result=`dfx canister call SwapFactory getInitArgs`
    echo "SwapFactory getInitArgs: $result"
}
#----------------- test withdraw mistransfer balance ------------------------

#----------------- test factory passcode crud ------------------------
function test_factory_passcode()
{
    result=`dfx canister call SwapFactory addPasscode "(principal \"$(dfx identity get-principal)\", record { token0 = principal \"$token0\"; token1 = principal \"$token1\"; fee = 3000; })"`
    echo "SwapFactory addPasscode: $result"

    result=`dfx canister call SwapFactory getPrincipalPasscodes`
    echo "SwapFactory getPrincipalPasscodes: $result"
    
    result=`dfx canister call SwapFactory deletePasscode "(principal \"$(dfx identity get-principal)\", record { token0 = principal \"$token0\"; token1 = principal \"$token1\"; fee = 3000; })"`
    echo "SwapFactory deletePasscode: $result"
}
#----------------- test factory passcode crud ------------------------


# Refresh and check position income
# Example: income 1 -23040 46080
# Args:
#   $1: Position ID
#   $2: Lower tick
#   $3: Upper tick
function income()
{
  echo "=== refreshIncome... ==="
  result=`dfx canister call $poolId refreshIncome "($1: nat)"`
  echo "refreshIncome result: $result"
  result=`dfx canister call $poolId getUserPosition "($1: nat)"`
  result=`dfx canister call $poolId getPosition "(record {tickLower = $2: int; tickUpper = $3: int})"`
}