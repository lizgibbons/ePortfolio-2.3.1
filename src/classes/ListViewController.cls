public with sharing class ListViewController {
	
	public List<String> catList {get; set;}
	//uses unique category__c as key and map of assets for that category
	public Map<String, Map<Id,Asset__c>> assetCatMap {get; set;}
	//temp asset Map
	public Map<Id, Asset__c>  assetMap {get; set;}
	//list of all assets
	public List<Asset__c> assetList {get; set;}
	//tracks the current Category__c to know when it changes
	public String currentCat {get; set;}

	
	
	public ListViewController(){
		catList = new List<String>();
		Schema.DescribeFieldResult fieldResult = Asset__c.Category__c.getDescribe();
		System.debug(fieldResult);
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		System.debug('--ple-->> ' + ple);
		for(Schema.PicklistEntry f : ple){
			catList.add(f.getLabel());
		}
		
		assetList = [select ID, Name, Category__c, LastModifiedDate from Asset__c where User__c = :UserInfo.getUserId() order by Category__c]; //get records
		assetCatMap = new Map<String, Map<Id,Asset__c>>();
		assetMap = new Map<Id, Asset__c>();	
	
		currentCat = null;
		
		for(String c :catList){
			assetCatMap.put(c, null);
		}
		
		for(Integer i = 0; i< assetList.size(); i++){
			//save currentCat of first asset
			if(currentCat == null){
				currentCat = assetList[i].Category__c;
			}
			
			//if category__c has changed or if it's the last record, save the assetMap for the category__c
			if(currentCat != assetList[i].Category__c || assetList.size() == i+1){
				//if only one record add asset to the map first
				if(i == 0){assetMap.put(assetList[i].Id, assetList[i]);}
				//add current category and asset map to the category map
				assetCatMap.put(currentCat, assetMap.clone());
				assetMap.clear();
				//declare new category
				currentCat = assetList[i].Category__c;

			}			
			
			assetMap.put(assetList[i].Id, assetList[i]);
			
		}
		
		for(String c :catList){
		
			if(assetCatMap.get(c) == null){
				assetCatMap.put(c, new Map<Id, Asset__c>());
			}
			
		}	
		
	}

}