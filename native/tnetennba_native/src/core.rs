use itertools::Itertools;
use std::{
    env,
    fs::File,
    io::{self, BufRead},
};

use chrono::{Datelike, FixedOffset, Utc};

pub fn is_good_guess(dictionary: &Vec<String>, word: &str, letter: &str, guess: &str) -> bool {
    guess.len() <= word.len()
        && guess.contains(letter)
        && is_partial_anagram(guess, word)
        && dictionary_contains(dictionary, guess)
}

fn dictionary_contains(dictionary: &Vec<String>, guess: &str) -> bool {
    dictionary.binary_search(&guess.to_owned()).is_ok()
}

pub fn get_words() -> Vec<String> {
    let is_prod = env::var("IS_PROD").is_ok();

    if is_prod {
        let file = File::open("real_words.txt").unwrap();
        io::BufReader::new(file)
            .lines()
            .map(|l| l.expect("Could not parse line"))
            .collect()
    } else {
        include_str!("test_words.txt")
            .lines()
            .map(|line| line.to_string())
            .collect()
    }
}

pub fn get_dictionary() -> Vec<String> {
    let file = File::open("filtered_dictionary.txt").unwrap();
    io::BufReader::new(file)
        .lines()
        .map(|l| l.expect("Could not parse line"))
        .collect()
}

fn is_partial_anagram(needle: &str, haystack: &str) -> bool {
    let haystack = haystack.chars().counts();
    let needle = needle.chars().counts();

    needle.iter().fold(true, |acc, (c, count)| {
        acc && { haystack.contains_key(c) && haystack.get(c).unwrap() >= count }
    })
}

pub fn get_todays_word(words: &Vec<String>, days_since_ce: usize) -> String {
    let idx = days_since_ce % words.len();

    words[idx].clone()
}

pub fn get_todays_letter(words: &Vec<String>, days_since_ce: usize) -> String {
    let word_idx: usize = days_since_ce % words.len();
    let letter_idx: usize = days_since_ce % words[word_idx].len();

    words[word_idx].chars().nth(letter_idx).unwrap().to_string()
}

pub fn get_days_since_ce() -> usize {
    // Get sydney time offset so we're vaguely based on aus time
    let offset = FixedOffset::east_opt(10 * 3600).unwrap();
    Utc::now().with_timezone(&offset).num_days_from_ce() as usize
}

#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn test_get_letter() {
        let words = vec!["asdf".to_owned(), "bbb".to_owned()];

        assert_eq!("b", get_todays_letter(&words, 1));
        assert_eq!("a", get_todays_letter(&words, 0));
    }

    #[test]
    fn test_partial_anagram() {
        assert!(is_partial_anagram("dfs", "asdf"));
        assert!(is_partial_anagram("tet", "test"));
        assert!(is_partial_anagram("tets", "test"));
        assert!(is_partial_anagram("tt", "test"));
        assert!(!is_partial_anagram("teta", "test"));
    }

    #[test]
    fn test_is_good_guess() {
        assert!(is_good_guess("test", "a", "tet"));
    }

    #[test]
    fn test_get_words() {
        assert_eq!(get_words().len(), 10);
    }

    #[test]
    fn test_get_word() {
        assert_eq!(get_todays_word(get_words(), 3), "unallayably");
    }
}
