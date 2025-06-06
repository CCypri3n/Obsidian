const notice = msg => new Notice(msg, 5000);
const log = msg => console.log(msg);

const API_KEY_OPTION = "OMDb API Key";
const API_URL = "https://www.omdbapi.com/";

module.exports = {
    entry: start,
    settings: {
        name: "Movie Script",
        author: "Christian B. B. Houmann and Cyprien Chevallier",
        options: {
            [API_KEY_OPTION]: {
                type: "text",
                defaultValue: "",
                placeholder: "OMDb API Key",
            },
        }
    }
}

let QuickAdd;
let Settings;

async function start(params, settings) {
    QuickAdd = params;
    Settings = settings;

    const query = await QuickAdd.quickAddApi.inputPrompt("Enter movie title or IMDB ID: ");
    if (!query) {
        notice("No query entered.");
        throw new Error("No query entered.");
    }

    let selectedShow;

    if (isImdbId(query)) {
        selectedShow = await getByImdbId(query);
    } else {
        const results = await getByQuery(query);

        const choice = await QuickAdd.quickAddApi.suggester(results.map(formatTitleForSuggestion), results);
        if (!choice) {
            notice("No choice selected.");
            throw new Error("No choice selected.");
        }

        selectedShow = await getByImdbId(choice.imdbID);
    }
    const isWatched = await QuickAdd.quickAddApi.yesNoPrompt("Have you watched this (partially)?");
    let watched;
    let myRating = "/10";
    let comment = "";
    let personal = "";
    
    if (isWatched) {
        if (selectedShow.Type !== "movie") {
            watched = await QuickAdd.quickAddApi.inputPrompt("How many Seasons have you watched?", "1, 2, 3, ...", "0");
        
            if (watched === "0") {
                const episodesWatched = await QuickAdd.quickAddApi.inputPrompt("How many Episodes have you watched?", "1, 2, 3, ...", "1");
                watched = `0 Seasons ∙ ${episodesWatched} ${episodesWatched === "1" ? "Episode" : "Episodes"}`;
            } else {
                watched = `${watched} ${watched === "1" ? "Season" : "Seasons"}`;
            }
        } else {
            watched = await QuickAdd.quickAddApi.inputPrompt("How many times have you watched the movie?", "1, 2, 3, ...", "1");
        }
        myRating = await QuickAdd.quickAddApi.inputPrompt("What would you rate this out of ten?", "/10", " ");
        comment = await QuickAdd.quickAddApi.inputPrompt("You can now write a review:", "Max Mustermann is hot, that is why i liked this!", " ");
        if (comment === " ") {
            comment = "No comment given"
        }
        personal = `⭐️ ${myRating}/10 ∙ ${getFormattedDate()}\n${selectedShow.Type === "movie" ? "" :  `${watched}\n`}${comment}`;
    }
    if (selectedShow.Year.length < 7 && selectedShow.Type !== "movie") {
        selectedShow.Year = selectedShow.Year.slice(0, -1); 
        selectedShow.Year = `${selectedShow.Year} - ${new Date().getFullYear()}`
    }
    let headline
    if (selectedShow.Runtime !== "N/A" && selectedShow.Rated !== "N/A" && selectedShow.Rated !== "Not Rated") {
        headline = `${selectedShow.Year} ∙ ${selectedShow.Runtime} ∙ ${selectedShow.Rated}`;
    } else if (selectedShow.Runtime !== "N/A") {
        headline = `${selectedShow.Year} ∙ ${selectedShow.Runtime}`;
    } else {
        headline = `${selectedShow.Year} ∙ ${selectedShow.Rated}`;
    }
    
    let castNote = " "
    if (selectedShow.Actors !== "N/A") {
        castNote = `**Cast:** ${linkifyListNote(selectedShow.Actors.split(","))}`;
    }

    let writerNote = " "
    if (selectedShow.Writer !== "N/A") {
        writerNote = `**Writer:** ${linkifyListNote(selectedShow.Writer.split(","))}`;
    }

    let directorNote = " "
    if (selectedShow.Director !== "N/A") {
        directorNote = `**Director:** ${linkifyListNote(selectedShow.Director.split(","))}`;
    }

    let tag = `\n  - ${selectedShow.Type === "movie" ? "movie" : "series"}\n  - ${isWatched ? "watched" : "to-watch"}`


    QuickAdd.variables = {
        ...selectedShow,
        actorLinks: linkifyList(selectedShow.Actors.split(",")),
        genreLinks: linkifyList(selectedShow.Genre.split(",")),
        directorLinks: linkifyList(selectedShow.Director.split(",")),
        writerLinks: linkifyList(selectedShow.Writer.split(",")),
        actorLink: linkifyListNote(selectedShow.Actors.split(",")),
        genreLink: linkifyListNote(selectedShow.Genre.split(",")),
        directorLink: linkifyListNote(selectedShow.Director.split(",")),
        writerLink: linkifyListNote(selectedShow.Writer.split(",")),
        castNote: castNote,
        writerNote: writerNote,
        directorNote: directorNote,
        fileName: replaceIllegalFileNameCharactersInString(selectedShow.Title),
        typeLinks: linkifyList([`${selectedShow.Type === "movie" ? "Movie" : "Series"}`, `Cinematography`]),
        languageLower: selectedShow.Language.toLowerCase(),
        headline: headline,
        watched: watched,
        comment: personal,
        rating: myRating,
        tag: tag,
    }
}

function isImdbId(str) {
    return /^tt\d+$/.test(str);
}

function formatTitleForSuggestion(resultItem) {
    return `(${resultItem.Type === "movie" ? "M" : "TV"}) ${resultItem.Title} (${resultItem.Year})`;
}

async function getByQuery(query) {
    const searchResults = await apiGet(API_URL, {
        "s": query,
    });

    if (!searchResults.Search || !searchResults.Search.length) {
        notice("No results found.");
        throw new Error("No results found.");
    }

    return searchResults.Search;
}

async function getByImdbId(id) {
    const res = await apiGet(API_URL, {
        "i": id
    });

    if (!res) {
        notice("No results found.");
        throw new Error("No results found.");
    }

    return res;
}

function linkifyList(list) {
    if (list.length === 0) return "";
    if (list.length === 1) return `\n  - "[[${list[0]}]]"`;

    return list.map(item => `\n  - "[[${item.trim()}]]"`).join("");
}

function linkifyListNote(list) {
    if (list.length === 0) return "";
    if (list.length === 1) return `[[${list[0]}]], `;

    return list.map(item => `[[${item.trim()}]]`).join(", ");
}

function replaceIllegalFileNameCharactersInString(string) {
    return string.replace(/[\\,#%&\{\}\/*<>$\'\":@]*/g, '');    
}

async function apiGet(url, data) {
    let finalURL = new URL(url);
    if (data)
        Object.keys(data).forEach(key => finalURL.searchParams.append(key, data[key]));

    finalURL.searchParams.append("apikey", Settings[API_KEY_OPTION]);

    const res = await request({
        url: finalURL.href,
        method: 'GET',
        cache: 'no-cache',
        headers: {
            'Content-Type': 'application/json',
        },
    });

    return JSON.parse(res);
}

function getFormattedDate() {
    const today = new Date();

    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0'); // Months are 0-based, so we add 1
    const day = String(today.getDate()).padStart(2, '0');

    return `${year}-${month}-${day}`;
}
