global function registerCallbacks
global function startMatch

const string BASE_URL = "http://localhost:5173"

struct {
    string matchId
} file

void function registerCallbacks()
{
    #if SERVER && MP
    AddCallback_GameStateEnter(eGameState.WaitingForPlayers, startMatch)
    AddCallback_GameStateEnter(eGameState.Prematch, addPlayersToTeams)
    AddCallback_GameStateEnter(eGameState.Postmatch, matchEnd)
    #endif
}

void function startMatch()
{
    string url = format( "%s/match/create", BASE_URL )
    NSHttpGet(url, {}, handleCreateMatch)
}

void function handleCreateMatch(HttpRequestResponse res)
{
    if (res.statusCode == 200)
    {
        table body = DecodeJSON(res.body)
        file.matchId = string(body["id"])
    }
}

void function addPlayersToTeams() 
{
    // add all players that are already in the game
    foreach(entity player in GetPlayerArray())
    {
        addPlayer(player)
    }
    // start listening for people coming in later
    AddCallback_OnClientConnected(addPlayer)
}

void function addPlayer(entity player)
{
    table body = {}
    body["teamId"] <- player.GetTeam()
    body["uid"] <- player.GetUID()
    body["name"] <- player.GetPlayerName()
    string url = format( "%s/match/%s/add_player", BASE_URL, file.matchId )
    NSHttpPostBody(url, EncodeJSON(body))
    
}

void function matchEnd()
{
    string url = format( "%s/match/%s/finish", BASE_URL, file.matchId )
    table body = {}

    table scores = {}
    foreach(int i in GetTeams())
    {
        if (i != TEAM_UNASSIGNED) {
            printt("Get score for team: ", i)
            scores[i] <- GameRules_GetTeamScore( i )       
        }
    }

    printt("Scores: ", scores)
    body["scores"] <- scores
    

    NSHttpPostBody(url, EncodeJSON(body))
}

array<int> function GetTeams()
{
    array<int> teams = []
    foreach(entity player in GetPlayerArray())
    {
        teams.push(player.GetTeam())
    }

    return teams
}
