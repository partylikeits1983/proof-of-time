use std::fs::File;
use std::io::{self, BufRead, Write};
use std::path::Path;
use std::time::{SystemTime, UNIX_EPOCH};

fn main() -> io::Result<()> {
    // Retrieve the RECIPIENT value from the environment
    // let recipient = env::var("RECIPIENT").expect("RECIPIENT not set in .env");

    // Paths for input data
    let root_path = Path::new("../data/root.txt");
    let siblings_path = Path::new("../data/proof_siblings.txt");
    let indices_path = Path::new("../data/proof_path_indices.txt");

    let timestamp_path = Path::new("../data/create_event_timestamp.txt");

    let nullifier_hash_path = Path::new("../data/prove_event_nullifier_hash.txt");

    // Paths for Prover.toml files
    let prove_event_output_path = Path::new("../circuits/prove_event/Prover.toml");
    let create_event_input_path = Path::new("../circuits/create_event/Prover.toml");

    // Open the withdraw Prover.toml file for writing
    let mut prove_event_file = File::create(&prove_event_output_path)?;

    // Read data from files
    let current_timestamp = get_current_timestamp()?;
    let create_timestamp = read_first_line(&timestamp_path)?;

    let nullifier_hash = read_first_line(&nullifier_hash_path)?;

    let root_value = read_first_line(&root_path)?;

    // Read secret and nullifier from deposit Prover.toml
    let (secret_value, nullifier_value) = read_prover_toml(&create_event_input_path)?;

    // Common fields for Prover.toml files
    let common_fields = |file: &mut File| -> io::Result<()> {
        writeln!(file, "current_timestamp = \"{}\"", current_timestamp)?;
        writeln!(file, "create_timestamp = \"{}\"", create_timestamp)?;
        writeln!(file, "root = \"{}\"", root_value)?;
        writeln!(file, "secret = \"{}\"", secret_value)?;
        writeln!(file, "nullifier = \"{}\"", nullifier_value)?;
        writeln!(file, "nullifier_hash = \"{}\"", nullifier_hash)?;
        writeln!(file, "proof_path_indices = [")?;
        for line in io::BufReader::new(File::open(&indices_path)?).lines() {
            let line = line?;
            writeln!(file, "    {},", line)?;
        }
        writeln!(file, "]")?;
        writeln!(file, "proof_siblings = [")?;
        for line in io::BufReader::new(File::open(&siblings_path)?).lines() {
            let line = line?;
            writeln!(file, "    \"{}\",", line)?;
        }
        writeln!(file, "]")?;

        Ok(())
    };

    // Write to withdraw Prover.toml
    common_fields(&mut prove_event_file)?;

    println!("prove_event Prover.toml formatted successfully");

    Ok(())
}

// Helper function to read the first line from a file
fn read_first_line(path: &Path) -> io::Result<String> {
    let file = File::open(path)?;
    let mut buf_reader = io::BufReader::new(file);
    let mut line = String::new();
    buf_reader.read_line(&mut line)?;
    Ok(line.trim_end().to_string())
}

// Helper function to get the current timestamp as a string
fn get_current_timestamp() -> io::Result<String> {
    let start = SystemTime::now();
    let since_the_epoch = start
        .duration_since(UNIX_EPOCH)
        .map_err(|e| io::Error::new(io::ErrorKind::Other, e))?;
    let timestamp = since_the_epoch.as_secs();

    // Convert timestamp to a 256-bit (64 hex characters) hexadecimal string
    // Pad with leading zeros and prefix with "0x"
    let hex_timestamp = format!("0x{:064x}", timestamp);

    Ok(hex_timestamp)
}

// Function to read secret and nullifier from Prover.toml
fn read_prover_toml(path: &Path) -> io::Result<(String, String)> {
    let file = File::open(path)?;
    let reader = io::BufReader::new(file);
    let mut secret = None;
    let mut nullifier = None;

    for line in reader.lines() {
        let line = line?;
        // Ignore comments and empty lines
        if line.trim().starts_with('#') || line.trim().is_empty() {
            continue;
        }

        if let Some(value) = parse_toml_line(&line, "secret") {
            secret = Some(value);
        }

        if let Some(value) = parse_toml_line(&line, "nullifier") {
            nullifier = Some(value);
        }

        // Break early if both values are found
        if secret.is_some() && nullifier.is_some() {
            break;
        }
    }

    match (secret, nullifier) {
        (Some(s), Some(n)) => Ok((s, n)),
        _ => Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "Missing secret or nullifier in Prover.toml",
        )),
    }
}

// Helper function to parse a specific key from a TOML line
fn parse_toml_line(line: &str, key: &str) -> Option<String> {
    if line.starts_with(key) {
        let parts: Vec<&str> = line.splitn(2, '=').collect();
        if parts.len() == 2 {
            // Remove possible whitespace and surrounding quotes
            let value = parts[1].trim().trim_matches('"').to_string();
            return Some(value);
        }
    }
    None
}
