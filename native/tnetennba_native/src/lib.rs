use rustler::{Env, Term};

pub mod core;

#[macro_use]
extern crate lazy_static;

#[rustler::nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif]
fn is_good_guess(word: &str, letter: &str, guess: &str) -> bool {
    core::is_good_guess(&DICTIONARY, word, letter, guess)
}

#[rustler::nif]
fn get_todays_word() -> String {
    core::get_todays_word(&WORDS, core::get_days_since_ce())
}

#[rustler::nif]
fn get_todays_letter() -> String {
    core::get_todays_letter(&WORDS, core::get_days_since_ce())
}

lazy_static! {
    pub static ref WORDS: Vec<String> = core::get_words();
    pub static ref DICTIONARY: Vec<String> = core::get_dictionary();
}

fn load(_env: Env, _: Term) -> bool {
    true
}

rustler::init!("Elixir.Tnetennba.Native", [is_good_guess, get_todays_word, get_todays_letter], load=load);