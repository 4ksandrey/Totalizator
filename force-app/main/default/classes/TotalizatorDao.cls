public with sharing class TotalizatorDao {
    public static List<Player__c> getPlayers(Integer limitNumber, Integer offset) {
        List<Player__c> notBlockedPlayers = [SELECT Name 
                                             FROM Player__c 
                                             WHERE IsBlackList__c = false 
                                             LIMIT :limitNumber OFFSET :offset];
        return notBlockedPlayers;
    }

    public static List<AggregateResult> getGamesCount() {
        List<AggregateResult> countOfAllGames = [SELECT COUNT(Name) total FROM Game__c];
        return countOfAllGames;
    }

    public static Map<Id, decimal> getTotalMoneyWon(Set<Id> playerIds) {
        List<AggregateResult> sumOfAllWonBets = [SELECT Player__c playerId, SUM(Amount__c) total
                                                 FROM Bet__c
                                                 WHERE Status__c = 'Won' AND Player__c IN :playerIds
                                                 GROUP BY Player__c];
        
        Map<ID, decimal> playersMapWithMoneyWon = new Map<ID, decimal>();
        for(AggregateResult wons : sumOfAllWonBets) {
            playersMapWithMoneyWon.put((Id) wons.get('playerId'), (decimal) wons.get('total'));
        }
        return playersMapWithMoneyWon;
    }

    public static List<Player__c> getTopPlayers(Integer limitNumber, Integer offset) {
        List<Player__c> topPlayers = [SELECT Name, TotalMoneyWon__c 
                                             FROM Player__c
                                             ORDER BY TotalMoneyWon__c desc
                                             LIMIT :limitNumber OFFSET :offset];
        return topPlayers;
    }

    public static Map<Id, Integer> getMostPopularGames() {
    	Map<Id, Integer> gameBetsCountMap = new Map<Id, Integer>();
		for (AggregateResult aggRes : [
      		SELECT count(ID) betsCount, Game__c gameId
      		FROM Bet__c
      		GROUP BY Game__c
		]) {
    	    Id gameId = (Id) aggRes.get('gameId');
    	    Integer betsCount = (Integer) aggRes.get('betsCount');
    	    gameBetsCountMap.put(gameId, betsCount);
		}
        return gameBetsCountMap;
    }

    public static void createPlayer(String playerName, String playerEmail) {
        List<Player__c> playerToInsert = new List<Player__c>();
    	playerToInsert.add(new Player__c(Name__c = playerName, Email__c = playerEmail));
        Database.SaveResult[] srList = Database.insert(playerToInsert, false);
        for (Database.SaveResult sr : srList) {
    		if (sr.isSuccess()) {
        		System.debug('Successfully inserted Player. Player ID: ' + sr.getId());
    		} else {              
        		for(Database.Error err : sr.getErrors()) {                   
            		System.debug(err.getStatusCode() + ': ' + err.getMessage());
            		System.debug('Player fields that affected this error: ' + err.getFields());
        		}
            }
		}
    }
    
    public static void updateBet(Id betId, Decimal amount, Decimal percent) {
        Bet__c betToUpdate = [SELECT Id, Amount__c, WinRate__c 
                              FROM Bet__c 
         				      WHERE Id = :betId AND Amount__c != null AND WinRate__c != null];
        betToUpdate.Amount__c = amount;
        betToUpdate.WinRate__c = percent;
        Database.SaveResult sr = Database.update(betToUpdate, false);  
        if (!sr.isSuccess()) {              
        	for(Database.Error err : sr.getErrors()) {                   
            	System.debug(err.getStatusCode() + ': ' + err.getMessage());
            	System.debug('Fields that affected this error: ' + err.getFields());
        	}
    	} else System.debug('Successfully updated Bet');
    }
    
    public static void deleteBets(List<Id> betIds) {
        List<Bet__c> betsToDelete = [SELECT Id FROM Bet__c WHERE Id IN :betIds];
        if(betsToDelete.size() > 0) {
        	List<Database.DeleteResult> results = Database.delete(betsToDelete, false);
        	for (Database.DeleteResult dr : results) {
    			if (dr.isSuccess()) {
        			System.debug('Successfully deleted Bet. Bet ID: ' + dr.getId());
    			} else {              
        			for(Database.Error err : dr.getErrors()) {                   
            			System.debug(err.getStatusCode() + ': ' + err.getMessage());
            			System.debug('Bet Id that affected this error: ' + dr.getId());
        			}
            	}
			}
        } else System.debug('Bets not found for delete');
    }
    
    public static void createBet(Id gameId, Id playerId, Decimal amount, Decimal winRate) {
        List<Bet__c> betsToInsert = new List<Bet__c>();
    	betsToInsert.add(new Bet__c(Game__c = gameId, Player__c = playerId, Amount__c = amount, WinRate__c = winRate, Status__c = 'Pending'));
        Database.SaveResult[] srList = Database.insert(betsToInsert, false);
        for (Database.SaveResult sr : srList) {
    		if (sr.isSuccess()) {
        		System.debug('Successfully inserted Bet. Bet ID: ' + sr.getId());
    		} else {              
        		for(Database.Error err : sr.getErrors()) {                   
            		System.debug(err.getStatusCode() + ': ' + err.getMessage());
            		System.debug('Bet fields that affected this error: ' + err.getFields());
        		}
            }
		}
    }
}
