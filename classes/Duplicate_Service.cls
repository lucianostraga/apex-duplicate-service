public class Duplicate_Service {
    
    public static List<Duplicate_Item> scanDuplicatesSingle(Id recordId){
                
        List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicatesByIds.findDuplicatesByIds(new List<Id>{recordId});
      
        return buildDuplicateItems(results);
    }
    
    public static List<Duplicate_Item> scanDuplicatesBulk(List<Id> recordIdsToAnalize){
        
        List<Duplicate_Item> dupList = new List<Duplicate_Item>();
        
        List<List<Id>> IdListsArray = splitRecordIdsToAnalize(recordIdsToAnalize);//SPLIT THE RECORD IDS IN LISTS OF 50 IDS
        
        for(List<Id> idList : IdListsArray){
            
            List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicatesByIds.findDuplicatesByIds(IdList);
            dupList.addAll(buildDuplicateItems(results));     
        }
        
        return dupList;  
    }
    
	public static void  processDuplicates(List<Id> recordIdsToAnalize){
        Map<String,Id> dupRulesMap = getDuplicateRulesMap();
        
        Map<Id,DuplicateRecordSet> recordSetMap = new  Map<Id,DuplicateRecordSet>();
        Map<Id,List<DuplicateRecordItem>> dupRecordItemsMap = new Map<Id,List<DuplicateRecordItem>>();
        
        List<List<Id>> IdListsArray = splitRecordIdsToAnalize(recordIdsToAnalize);//SPLIT THE RECORD IDS IN LISTS OF 50 IDS
                        
        for(List<Id> idList : IdListsArray){
            Integer idPossition = 0;

            if(!IdListsArray.isEmpty()){
                List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicatesByIds.findDuplicatesByIds(IdList);
                
                for(Datacloud.FindDuplicatesResult res : results){
                                     
                    for(Datacloud.DuplicateResult dupeResult : res.getDuplicateResults()){
                        
                        if(!dupeResult.getMatchResults().isEmpty()){//THERE ARE DUPLICATES
                            
                            DuplicateRecordSet dupRecSet = new DuplicateRecordSet(DuplicateRuleId = dupRulesMap.get(dupeResult.duplicaterule), 
                                                                                  Scanned_Record_Id__c = idList[idPossition],
                                                                                  Type__c = dupeResult.duplicateruleentitytype);
                        
                            recordSetMap.put(idList[idPossition],dupRecSet);
                            
                            List<DuplicateRecordItem> dupMatches = processDuplicatesMatches(dupeResult);
                            dupRecordItemsMap.put(idList[idPossition],dupMatches);
                            
                        }

                    }
                    
                    idPossition++;                                   
                }
            }

        }
        
        associateDupItemsWithDupRecordSets(recordSetMap,dupRecordItemsMap);
    }
    
    private static List<Duplicate_Item> buildDuplicateItems(List<Datacloud.FindDuplicatesResult> results){
        List<Duplicate_Item> dupList = new List<Duplicate_Item>();
        
        for(Datacloud.FindDuplicatesResult res : results){
            
                for(Datacloud.DuplicateResult dupeResult : res.getDuplicateResults()){
                    
                    if(!dupeResult.getMatchResults().isEmpty()){
                        
                        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                                                                                     
                            for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                                
                                Duplicate_Item dupItem = new Duplicate_Item();
                                dupItem.MatchType = matchResult.getMatchEngine();
                                dupItem.MatchConfidence = matchRecord.matchconfidence;
                                dupItem.RecordId = (Id) matchRecord.getRecord().get('Id');
                                dupItem.RecordName = (String) matchRecord.getRecord().get('Name');
                                dupItem.RecordType = matchResult.entitytype;
                                dupList.add(dupItem);
                                
                            }
                        }
                    }
                }  
            }
        
        return dupList;
    }
    
    private static void associateDupItemsWithDupRecordSets(Map<Id,DuplicateRecordSet> recordSetMap,Map<Id,List<DuplicateRecordItem>> dupRecordItemsMap){
        insert recordSetMap.values();
        List<DuplicateRecordItem> dupRecordsToInsert = new List<DuplicateRecordItem>();
      
        for(Id requestedId : dupRecordItemsMap.keySet()){
            
            List<DuplicateRecordItem> relatedDupItems = dupRecordItemsMap.get(requestedId);
            
            for(DuplicateRecordItem dupItem : relatedDupItems){
                dupItem.DuplicateRecordSetId = recordSetMap.get(requestedId).Id;
                dupRecordsToInsert.add(dupItem);
            }
            
        }
        insert dupRecordsToInsert;
    }
        
    private static Map<String,Id> getDuplicateRulesMap(){
        Map<String,Id> dupRulesMap = new Map<String,Id>();
        
        for(DuplicateRule dr : [SELECT Id , DeveloperName FROM DuplicateRule WHERE IsActive = TRUE]){
            dupRulesMap.put(dr.DeveloperName, dr.Id);
        }
        
        return dupRulesMap;
    }
    
    private static List<DuplicateRecordItem> processDuplicatesMatches(Datacloud.DuplicateResult dupeResult){
        
        List<DuplicateRecordItem> dupRecordItems = new List<DuplicateRecordItem>();
        
        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                                                                                 
            for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                
                DuplicateRecordItem dupItem = new DuplicateRecordItem();
                dupItem.Match_Engine__c = matchResult.getMatchEngine();
                dupItem.Match_Confidence__c = matchRecord.matchconfidence;
                dupItem.Service_Full_Response__c = Json.serialize(matchRecord.getFieldDiffs());
                dupItem.RecordId = (Id) matchRecord.getRecord().get('Id');
                dupItem.Type__c = matchResult.entitytype;
                dupRecordItems.add(dupItem);
                
            }
        }
        
        return dupRecordItems;
    }
    
	private static List<List<Id>> splitRecordIdsToAnalize(List<Id> recordIdsToAnalyze){

        List<List<Id>> IdListsArray = new List<List<Id>>();
        Integer currentList;

        for(Id recId : recordIdsToAnalyze){
            if(IdListsArray.isEmpty()){
                List<Id> newList = new List<Id>();
                newList.add(recId);                
                IdListsArray.add(newList);
                currentList = 0;
            }else if(IdListsArray[currentList].size() == 50){//UP TO 50 RECORDS PER LIST PER DUPLICATION LIMITS
                List<Id> newList = new List<Id>();
                newList.add(recId);
                IdListsArray.add(newList);
                currentList++;
            }else{//CURRENT LIST IS NOT FULL
                IdListsArray[currentList].add(recId);
            }            

        }
        
        return IdListsArray;
    } 
    
    public class Duplicate_Item{
        @AuraEnabled public String RecordId;
        @AuraEnabled public String RecordName;
        @AuraEnabled public String RecordType;
        @AuraEnabled public String MatchType;
        @AuraEnabled public Double MatchConfidence;
    }
    
}