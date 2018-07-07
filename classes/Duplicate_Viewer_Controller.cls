public class Duplicate_Viewer_Controller {
    
    @AuraEnabled
    public static List<Duplicate_Service.Duplicate_Item> getDuplicatesByRecordId(String stringRecordId){
        
        try{
            Id recordId = Id.valueOf(stringRecordId);
			return Duplicate_Service.scanDuplicatesSingle(recordId);            
        }
        catch(Exception e){
            throw new AuraHandledException('Error: Invalid Id');
        }
    }
    
}