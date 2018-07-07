public class Look_For_Duplicates_Invocable {
    
    @InvocableMethod(label='Analyze Duplicates' description='Receives a list of record ids and checks for duplicates')
    public static void analyzeDuplicates(List<Id> recordIdsToAnalize){
        Duplicate_Service.processDuplicates(recordIdsToAnalize);
    }

}