global function registerCallbacks
global function startMatch

struct {
    string matchId,
    string apiKey,
    string baseUrl,
    table< string, array< string > > headers
} file

const LOGGING_PREFIX = "[40MM] "

void function registerCallbacks()
{
    file.baseUrl = GetConVarString( "40mm_api_url" )
    string key = GetConVarString( "40mm_api_key" )
    if ( file.apiKey == "none") {
        printt("API key was not set, not starting Tone tracking")
    } else {
        file.apiKey = key
        file.headers["Authorization"] <- [ format( "Bearer %s", file.apiKey) ]
        printt( LOGGING_PREFIX, "Using API url ", file.baseUrl )
        AddCallback_GameStateEnter(eGameState.Playing, startMatch)
        AddCallback_GameStateEnter(eGameState.WinnerDetermined, matchEnd)
    }
}

void function startMatch()
{
    HttpRequest request
    request.url = format( "%s/match/create", file.baseUrl )
    request.method = HttpRequestMethod.GET
    request.headers = file.headers
    NSHttpRequest(request, handleCreateMatch, handleError)


}

void function handleCreateMatch(HttpRequestResponse res)
{
    if (res.statusCode == 200)
    {
        table body = DecodeJSON(res.body)
        file.matchId = string(body["id"])
        printt(LOGGING_PREFIX, "Created match with ID ", file.matchId)

        addPlayersToTeams()
    } else 
    {
        printt(LOGGING_PREFIX, "Server returned an error when creating the match")
        printt(LOGGING_PREFIX, "Status code ", res.statusCode)
        printt(LOGGING_PREFIX, res.body)
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
    body["uid"] <- player.GetUID()
    body["name"] <- player.GetPlayerName()

    HttpRequest request
    request.method = HttpRequestMethod.POST
    request.url = format( "%s/player/add", file.baseUrl )
    request.headers = file.headers
    request.body = EncodeJSON(body)
    NSHttpRequest(request, null, handleError)

    printt( LOGGING_PREFIX, "Sent player '", player.GetUID(), "' to the server")

    foreach(entity player in GetPlayerArray())
    {
        //TODO: Send url for web interface?
        NSSendInfoMessageToPlayer(player, "This server has 40mm tracking enabled")
    }
    
}

void function matchEnd()
{
    string url = format( "%s/match/%s/submit", file.baseUrl, file.matchId )
    array< table > teams = []


    foreach(int i in GetTeams())
    {
        table team
        if (i != TEAM_UNASSIGNED) {
            printt(LOGGING_PREFIX, "Get score for team: ", i)
            team["score"] <- GameRules_GetTeamScore( i )       
        }

        array<entity> players = GetPlayerArrayOfTeam ( i )
        array playerIDs = []
        foreach(entity player in players) 
        {
            playerIDs.push(player.GetUID())
        }

        team["players"] <- playerIDs

        teams.push(team)
        
    }

    table< string, array< table > > body = {}
    body["teams"] <- teams

    HttpRequest request
    request.method = HttpRequestMethod.POST
    request.url = url
    request.body = EncodeJSON(body)
    request.headers = file.headers
    

    NSHttpRequest(request, null, handleError)
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

void function handleError(HttpRequestFailure error)
{
    printt( LOGGING_PREFIX, "HTTP request failed: ", error.errorMessage )
    printt( LOGGING_PREFIX, "Server URL: ", file.baseUrl )
}
