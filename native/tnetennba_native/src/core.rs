use itertools::Itertools;
use std::env;

use chrono::{Datelike, FixedOffset, Utc};

pub fn is_good_guess(word: &str, letter: &str, guess: &str) -> bool {
    guess.len() <= word.len()
        && guess.contains(letter)
        && is_partial_anagram(guess, word)
        && dictionary_contains(guess)
}

fn dictionary_contains(_guess: &str) -> bool {
    true
}
pub fn get_words() -> Vec<String> {
    let is_prod = env::var("IS_PROD").is_ok();

    if is_prod {
        // TODO: Pull from s3 populated file
        include_str!("test_words.txt")
            .lines()
            .map(|line| line.to_string())
            .collect()
    } else {
        include_str!("test_words.txt")
            .lines()
            .map(|line| line.to_string())
            .collect()
    }
}

fn is_partial_anagram(needle: &str, haystack: &str) -> bool {
    let haystack = haystack.chars().counts();
    let needle = needle.chars().counts();

    needle.iter().fold(true, |acc, (c, count)| {
        acc && { haystack.contains_key(c) && haystack.get(c).unwrap() >= count }
    })
}

pub fn get_todays_word(words: Vec<String>, days_since_ce: usize) -> String {
    let idx = days_since_ce % words.len();

    words[idx].clone()
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
