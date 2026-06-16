import csv
import os

# Paths to input .dat files
MOVIES_DAT = os.path.join("ml-1m", "movies.dat")
RATINGS_DAT = os.path.join("ml-1m", "ratings.dat")
USERS_DAT = os.path.join("ml-1m", "users.dat")

# Paths to output .csv files
os.makedirs("import", exist_ok=True)
MOVIES_CSV = os.path.join("import", "movies.csv")
RATINGS_CSV = os.path.join("import", "ratings.csv")
USERS_CSV = os.path.join("import", "users.csv")

# 1. Convert movies.dat -> import/movies.csv
# movies.dat: MovieID::Title::Genres
print(f"Converting {MOVIES_DAT} -> {MOVIES_CSV}...")
with open(MOVIES_DAT, 'r', encoding='latin-1') as f_in, \
     open(MOVIES_CSV, 'w', newline='', encoding='utf-8') as f_out:
    writer = csv.writer(f_out)
    writer.writerow(['movieId', 'title', 'genres'])
    for line in f_in:
        parts = line.strip().split('::')
        writer.writerow(parts)

# 2. Convert ratings.dat -> import/ratings.csv
# ratings.dat: UserID::MovieID::Rating::Timestamp
print(f"Converting {RATINGS_DAT} -> {RATINGS_CSV}...")
with open(RATINGS_DAT, 'r', encoding='latin-1') as f_in, \
     open(RATINGS_CSV, 'w', newline='', encoding='utf-8') as f_out:
    writer = csv.writer(f_out)
    writer.writerow(['userId', 'movieId', 'rating', 'timestamp'])
    for line in f_in:
        parts = line.strip().split('::')
        writer.writerow(parts)

# 3. Convert users.dat -> import/users.csv
# users.dat: UserID::Gender::Age::Occupation::Zip
print(f"Converting {USERS_DAT} -> {USERS_CSV}...")
with open(USERS_DAT, 'r', encoding='latin-1') as f_in, \
     open(USERS_CSV, 'w', newline='', encoding='utf-8') as f_out:
    writer = csv.writer(f_out)
    writer.writerow(['userId', 'gender', 'age', 'occupation'])
    for line in f_in:
        parts = line.strip().split('::')
        writer.writerow(parts[:4])  # zip code is not needed

print("Data conversion complete.")
