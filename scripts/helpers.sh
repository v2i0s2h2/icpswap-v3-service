#!/bin/bash
# Helper functions for swap operations

# "PasscodeManager" canister ke paas ICRC2 token mein kitna balance hai, wo check karti hai.
function balanceOf()
{
  if [ $3 = "null" ]; then
    subaccount="null"
  else
    subaccount="opt principal \"$3\""
  fi
  balance=`dfx canister call Test testTokenAdapterBalanceOf "(\"$1\", \"DIP20\", principal \"$2\", $subaccount)"`
  echo $balance
}

# Create a new liquidity pool with initial price
# Example: create_pool 274450166607934908532224538203
# Kyuki price ratio hota hai do tokens ke beech (Token1/Token0).
function create_pool() #sqrtPriceX96
{
  # Setup approvals and create pool
  dfx canister call ICRC2 icrc2_approve "(record{amount=1000000000000;created_at_time=null;expected_allowance=null;expires_at=null;fee=null;from_subaccount=null;memo=null;spender=record {owner= principal \"$(dfx canister id PasscodeManager)\";subaccount=null;}})"
  dfx canister call PasscodeManager depositFrom "(record {amount=100000000;fee=0;})"
  dfx canister call PasscodeManager requestPasscode "(principal \"$token0\", principal \"$token1\", 3000)"
  
  # Create pool and setup approvals
  result=`dfx canister call SwapFactory createPool "(record {subnet = opt \"mainnet\"; token0 = record {address = \"$token0\"; standard = \"DIP20\";}; token1 = record {address = \"$token1\"; standard = \"DIP20\";}; fee = 3000; sqrtPriceX96 = \"$1\"})"`
  if [[ ! "$result" =~ " ok = record " ]]; then
    echo "\033[31mcreate pool fail. $result - \033[0m"
  fi
  echo "create_pool result: $result"
  poolId=`echo $result | awk -F"canisterId = principal \"" '{print $2}' | awk -F"\";" '{print $1}'`
  
  dfx canister call $dipAId approve "(principal \"$poolId\", $TOTAL_SUPPLY)"
  dfx canister call $dipBId approve "(principal \"$poolId\", $TOTAL_SUPPLY)"
  dfx canister call PositionIndex updatePoolIds 
  
  # Setup initial balances and transfers
  balance=`dfx canister call Test testTokenAdapterBalanceOf "(\"$(dfx canister id ICRC2)\", \"ICRC2\", principal \"$poolId\", null)"`
  echo $balance
  balance=`dfx canister call Test testTokenAdapterBalanceOf "(\"$(dfx canister id ICRC2)\", \"ICRC2\", principal \"$(dfx canister id PasscodeManager)\", null)"`
  echo $balance
  dfx canister call PasscodeManager transferValidate "(principal \"$poolId\", $TOTAL_SUPPLY)"
  dfx canister call PasscodeManager transferValidate "(principal \"$poolId\", 100000000)"
  dfx canister call PasscodeManager transfer "(principal \"$poolId\", 99999000)"
  balance=`dfx canister call Test testTokenAdapterBalanceOf "(\"$(dfx canister id ICRC2)\", \"ICRC2\", principal \"$poolId\", null)"`
  echo $balance
}

# Deposit tokens into the pool
# Liquidity position banane se pehle, aapko dono tokens separately deposit karne padte hain.
# Order Matters: Pehle deposit, phir mint() ya swap().
# Example: depost "ryjl3-tyaaa-aaaaa-aaaba-cai" 1000000
# Args:
#   $1: Token canister ID
#   $2: Amount to deposit
function depost() # token tokenAmount
{   
  echo "=== pool deposit  ==="
  result=`dfx canister call $poolId depositFrom "(record {token = \"$1\"; amount = $2: nat; fee = $TRANS_FEE: nat; })"`
  result=${result//"_"/""}
  if [[ "$result" =~ "$2" ]]; then
    echo "\033[32m deposit $1 success. \033[0m"
  else
    echo "\033[31m deposit $1 fail. $result, $2 \033[0m"
  fi
}

# Add liquidity to create a new position
# Example: mint -23040 46080 100000000000 92884678893 1667302813453 1573153132015
# Args:
#   $1: Lower tick
#   $2: Upper tick 
#   $3: Desired amount of token0
#   $4: Minimum amount of token0
#   $5: Desired amount of token1
#   $6: Minimum amount of token1
function mint()
{
  result=`dfx canister call $poolId mint "(record { token0 = \"$token0\"; token1 = \"$token1\"; fee = 3000: nat; tickLower = $1: int; tickUpper = $2: int; amount0Desired = \"$3\"; amount1Desired = \"$5\"; })"`
  info=`dfx canister call $poolId metadata`
  info=${info//"_"/""}
  if [[ "$info" =~ "$7" ]] && [[ "$info" =~ "$8" ]] && [[ "$info" =~ "$9" ]]; then
    echo "\033[32m mint success. \033[0m"
  else
    echo "\033[31m mint fail. $info \n expected $7 $8 $9 \033[0m"
  fi
  dfx canister call PositionIndex addPoolId "(\"$poolId\")"
}

# Increase liquidity in existing position
# Example: increase 1 100000000000 95000000000 1667302813453 1583937672780
# Args:
#   $1: Position ID
#   $2: Desired amount of token0
#   $3: Minimum amount of token0
#   $4: Desired amount of token1
#   $5: Minimum amount of token1 
function increase()
{
  echo "=== increase... ==="
  result=`dfx canister call $poolId increaseLiquidity "(record { positionId = $1 :nat; amount0Desired = \"$2\"; amount1Desired = \"$4\"; })"`
  echo "increase result: $result"
  
  info=`dfx canister call $poolId metadata`
  info=${info//"_"/""}
  if [[ "$info" =~ "$6" ]] && [[ "$info" =~ "$7" ]] && [[ "$info" =~ "$8" ]]; then
    echo "\033[32m increase success. \033[0m"
  else
    echo "\033[31m increase fail. $info \n expected $6 $7 $8 \033[0m"
  fi
}

# Decrease liquidity from a position 
# Example: decrease 1 500000000 47500000 791500000
# Args:
#   $1: Position ID
#   $2: Amount of liquidity to remove
#   $3: Minimum amount of token0 to receive
#   $4: Minimum amount of token1 to receive
function decrease()
{
  echo "=== decrease... ==="
  result=`dfx canister call $poolId getUserPosition "($1: nat)"`
  echo "user position result: $result"
  result=`dfx canister call $poolId decreaseLiquidity "(record { positionId = $1 :nat; liquidity = \"$2\"; })"`
  echo "decrease result: $result"

  # Handle withdrawals of tokens
  result=`dfx canister call $poolId getUserUnusedBalance "(principal \"$MINTER_PRINCIPAL\")"`
  echo "unused balance result: $result"

  withdrawAmount0=$(echo "$result" | sed -n 's/.*balance0 = \([0-9_]*\) : nat.*/\1/p' | sed 's/[^0-9]//g')
  withdrawAmount1=$(echo "$result" | sed -n 's/.*balance1 = \([0-9_]*\) : nat.*/\1/p' | sed 's/[^0-9]//g')
  echo "withdraw amount0: $withdrawAmount0"
  echo "withdraw amount1: $withdrawAmount1"

  if [ "$withdrawAmount0" -ne 0 ]; then
    result=`dfx canister call $poolId withdraw "(record {token = \"$token0\"; fee = $TRANS_FEE: nat; amount = $withdrawAmount0: nat;})"`
    echo "token0 withdraw result: $result"
  fi
  if [ "$withdrawAmount1" -ne 0 ]; then
    result=`dfx canister call $poolId withdraw "(record {token = \"$token1\"; fee = $TRANS_FEE: nat; amount = $withdrawAmount1: nat;})"`
    echo "token1 withdraw result: $result"
  fi

  info=`dfx canister call $poolId metadata`
  info=${info//"_"/""}
  if [[ "$info" =~ "$5" ]] && [[ "$info" =~ "$6" ]] && [[ "$info" =~ "$7" ]]; then
    echo "\033[32m decrease liquidity success. \033[0m"
  else
    echo "\033[31m decrease liquidity fail. $info \n expected $5 $6 $7 \033[0m"
  fi
  dfx canister call PositionIndex removePoolId "(\"$poolId\")"
}

# Get quote for swap
# Example: quote 1000000 950000
# Args:
#   $1: Input amount
#   $2: Minimum output amount
function quote()
{ 
  echo "=== quote... ==="
  result=`dfx canister call $poolId quote "(record { zeroForOne = true; amountIn = \"$1\"; amountOutMinimum = \"$2\"; })"`
  echo "quote result: $result"
}

# Execute token swap
# Example: swap "ryjl3-tyaaa-aaaaa-aaaba-cai" 1000000 950000 900000
# Args:
#   $1: Token to swap from
#   $2: Amount to deposit
#   $3: Amount to swap
#   $4: Minimum amount to receive
function swap()
{
  echo "=== swap... ==="
  depost $1 $2    
  if [[ "$1" =~ "$token0" ]]; then
    result=`dfx canister call $poolId swap "(record { zeroForOne = true; amountIn = \"$3\"; amountOutMinimum = \"$4\"; })"`
  else
    result=`dfx canister call $poolId swap "(record { zeroForOne = false; amountIn = \"$3\"; amountOutMinimum = \"$4\"; })"`
  fi
  echo "swap result: $result"

  # Handle unused balances
  result=`dfx canister call $poolId getUserUnusedBalance "(principal \"$MINTER_PRINCIPAL\")"`
  echo "unused balance result: $result"

  withdrawAmount0=$(echo "$result" | sed -n 's/.*balance0 = \([0-9_]*\) : nat.*/\1/p' | sed 's/[^0-9]//g')
  withdrawAmount1=$(echo "$result" | sed -n 's/.*balance1 = \([0-9_]*\) : nat.*/\1/p' | sed 's/[^0-9]//g')
  echo "withdraw amount0: $withdrawAmount0"
  echo "withdraw amount1: $withdrawAmount1"

  # Withdraw remaining balances
  result=`dfx canister call $poolId withdraw "(record {token = \"$token0\"; fee = $TRANS_FEE: nat; amount = $withdrawAmount0: nat;})"`
  echo "token0 withdraw result: $result"
  result=`dfx canister call $poolId withdraw "(record {token = \"$token1\"; fee = $TRANS_FEE: nat; amount = $withdrawAmount1: nat;})"`
  echo "token1 withdraw result: $result"
  
  # Verify balances
  token0BalanceResult="$(balanceOf $token0 $MINTER_PRINCIPAL null)"
  echo "token0 $MINTER_PRINCIPAL balance: $token0BalanceResult"
  token1BalanceResult="$(balanceOf $token1 $MINTER_PRINCIPAL null)"
  echo "token1 $MINTER_PRINCIPAL balance: $token1BalanceResult"
  info=`dfx canister call $poolId metadata`
  info=${info//"_"/""}
  token0BalanceResult=${token0BalanceResult//"_"/""}
  token1BalanceResult=${token1BalanceResult//"_"/""}
  if [[ "$info" =~ "$5" ]] && [[ "$info" =~ "$6" ]] && [[ "$info" =~ "$7" ]] && [[ "$token0BalanceResult" =~ "$8" ]] && [[ "$token1BalanceResult" =~ "$9" ]]; then
    echo "\033[32m swap success. \033[0m"
  else
    echo "\033[31m swap fail. $info \n expected $5 $6 $7 $8 $9\033[0m"
  fi
}

# Check token balances match expected values
# Example: checkBalance 999999900000000000 999998332697186547
# Args:
#   $1: Expected token0 balance
#   $2: Expected token1 balance 
function checkBalance(){
  token0BalanceResult="$(balanceOf $token0 $MINTER_PRINCIPAL null)"
  echo "token0 $MINTER_PRINCIPAL balance: $token0BalanceResult"
  token1BalanceResult="$(balanceOf $token1 $MINTER_PRINCIPAL null)"
  echo "token1 $MINTER_PRINCIPAL balance: $token1BalanceResult"
  token0BalanceResult=${token0BalanceResult//"_"/""}
  token1BalanceResult=${token1BalanceResult//"_"/""}
  if [[ "$token0BalanceResult" =~ "$1" ]] && [[ "$token1BalanceResult" =~ "$2" ]]; then
    echo "\033[32m token balance success. \033[0m"
  else
    echo "\033[31m token balance fail. $info \n expected $1 $2\033[0m"
  fi
}
