#[contract]
mod ERC20 {}

use zeroable::Zeroable;
use starknet::get_caller_address;
use starknet::contract_address_const;
use starknet::ContractAddress;
use starknet::ContractAddressZeroable;

struct Storage {
    name: felt252,
    symbol: felt252,
    decimals: u8,
    total_supply: u256,
    balances: LegacyMap::<ContractAddress, u256>,
    allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,
}

#[event]
fn Transfer(from: ContractAddress, to: ContractAddress, value: u256) {}

#[event]
fn Approval(owner: ContractAddress, spender: ContractAddress, value: u256) {}

#[constructor]
fn constructor(
    name_: felt252,
    symbol_: felt252,
    decimals_: u8,
    initial_supply: u256,
    recipient: ContractAddress
) {
    name::write(name_);
    symbol::write(symbol_);
    decimals::write(decimals_);
    assert(!recipient.is_zero(), 'ERC20: mint to the 0 address');
    total_supply::write(initial_supply);
    balances::write(recipient, initial_supply);
    Transfer(contract_address_const::<0>(), recipient, initial_supply);
}

#[external]
fn name() -> (felt252) {
    return name::read();
}

#[external]
fn symbol() -> (felt252) {
    return symbol::read();
}

#[external]
fn decimals() -> (u8) {
    return decimals::read();
}

#[external]
fn totalSupply() -> (u256) {
    return total_supply::read();
}

#[external]
fn balanceOf(owner: ContractAddress) -> (u256) {
    return balances::read(owner);
}

#[external]
fn transfer(recipient: ContractAddress, amount: u256) {
    let sender = get_caller_address();
    transfer_helper(sender, recipient, amount);
}

fn transfer_helper(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
    assert(!sender.is_zero(), 'ERC20: transfer from 0');
    assert(!recipient.is_zero(), 'ERC20: transfer to 0');
    balances::write(sender, balances::read(sender) - amount);
    balances::write(recipient, balances::read(recipient) + amount);
    Transfer(sender, recipient, amount);
}

#[external]
fn approve(spender: ContractAddress, amount: u256) {
    let owner = get_caller_address();
    approve_helper(owner, spender, amount);
}

fn approve_helper(owner: ContractAddress, spender: ContractAddress, amount: u256) {
    assert(!owner.is_zero(), 'ERC20: approve from 0');
    assert(!spender.is_zero(), 'ERC20: approve to 0');
    allowances::write((owner, spender), amount);
    Approval(owner, spender, amount);
}

#[external]
fn allowance(owner: ContractAddress, spender: ContractAddress) -> (u256) {
    return allowances::read((owner, spender));
}

#[external]
fn transferFrom(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
    let caller = get_caller_address();
    let allowance = allowances::read((sender, caller));
    assert(!sender.is_zero(), 'ERC20: transfer from 0');
    assert(!recipient.is_zero(), 'ERC20: transfer to 0');
    assert(amount <= allowance, 'ERC20: transfer amount exceeds allowance');
    balances::write(sender, balances::read(sender) - amount);
    balances::write(recipient, balances::read(recipient) + amount);
    allowances::write((sender, caller), allowance - amount);
    Transfer(sender, recipient, amount);
}

#[external]
fn mint(recipient: ContractAddress, amount: u256) {
    assert(!recipient.is_zero(), 'ERC20: mint to the 0 address');
    let current_total_supply = total_supply::read();
    total_supply::write(current_total_supply + amount);
    balances::write(recipient, balances::read(recipient) + amount);
    Transfer(contract_address_const::<0>(), recipient, amount);
}

#[external]
fn burn(amount: u256) {
    let caller = get_caller_address();
    let caller_balance = balances::read(caller);
    assert(amount <= caller_balance, 'ERC20: burn amount exceeds balance');
    balances::write(caller, caller_balance - amount);
    total_supply::write(total_supply::read() - amount);
    Transfer(caller, contract_address_const::<0>(), amount);
}
