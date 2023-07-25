use rustler::{Env, Term};

pub mod core;

#[rustler::nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif]
fn is_good_guess(word: &str, letter: &str, guess: &str) -> bool {
    core::is_good_guess(word, letter, guess)
}

#[rustler::nif]
fn get_todays_word() -> String {
    core::get_todays_word(core::get_words(), core::get_days_since_ce())
}

fn load(_env: Env, _: Term) -> bool {
    true
}

rustler::init!("Elixir.Tnetennba.Native", [is_good_guess, get_todays_word], load=load);