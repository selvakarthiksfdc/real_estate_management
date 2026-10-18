public with sharing class CreateNewPropertyController {
    
    public class FileWrapper{
        @AuraEnabled public string fileName {get; set;}
        @AuraEnabled public string fileContent {get; set;}
    }
    
    @AuraEnabled
    public static string CreateNewPropMethod(string propertyJson, list<FileWrapper> files){
        try{
            property__c propertyRecord=(property__c) JSON.deserialize(propertyJson, property__c.class);
			INSERT propertyRecord;
            
            list<contentVersion>cvs=new list<contentVersion>();
            for (FileWrapper fw:files){
                contentVersion cv=new contentVersion();
                cv.title=fw.fileName;
                cv.PathOnClient=fw.fileName;
                cv.versiondata=EncodingUtil.base64Decode(fw.fileContent);
                cv.FirstPublishLocationId=propertyRecord.Id;
                
                cvs.add(cv);
            }
            
            INSERT cvs;
			
			return propertyRecord.Id;            
        }
        catch(Exception e){
           throw new AuraHandledException(e.getMessage()) ;
        }
    }
}