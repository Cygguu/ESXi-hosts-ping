# PowerShell Script to Ping ESXi Hosts from ServiceNow

This PowerShell script is designed to ping multiple remote ESXi hosts whose names are specified in a CSV file exported from ServiceNow. The script reads hostnames from a specific column (`short_description`) in the CSV file, checks for any hostnames that start with "ESXi host", and then pings each identified host four times. The results are logged in a file for review.

## Prerequisites

- PowerShell 5.0 or higher.
- A CSV file exported from ServiceNow containing hostnames.

## Usage

1. Place the PowerShell script in the same directory as your CSV file.
2. Ensure the exported file from ServiceNow is in `.csv` format.
3. Run the script using PowerShell.
4. The results will be logged in a file named `ping_results.txt` in the same directory as the script.

## How It Works

- The script will check for a single CSV file in the directory where it is run.
- It reads the hostnames from the `short_description` column in the CSV file.
- It filters the hostnames that begin with the string "ESXi host".
- The script then pings each identified host four times.
- Ping results are logged into `ping_results.txt` for review.

## Notes

- If there are multiple CSV files in the directory, the script will terminate and prompt you to ensure only one file is present.
- The script assumes that only one CSV file is in the directory alongside the script.

## Example of a CSV File

Here is an example of how the CSV file should be structured (note that the relevant column is `short_description`):

```csv
short_description,other_column
"ESXi host 192.168.1.1", "Additional data"
"ESXi host 192.168.1.2", "More data"


License
This script is provided under the MIT License. Feel free to modify and use it as needed for your purposes.

Support
If you encounter any issues or have questions, feel free to open an issue in this repository.

Created by Jakub Zyzanski
