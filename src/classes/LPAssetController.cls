public without sharing class LPAssetController {

	/* Grabs motivislp__ */
	public String getPrefix() {
		return LPUtils.getPackagePrefix();
	}

	public LPAssetController() {
	}

	private ApexPages.StandardController stdctrl;

	public LPAssetController(ApexPages.StandardController stdController) {
		stdctrl = stdController;
	}

	// COMMON
	/* Category picklist for Content*/
	public Schema.PicklistEntry getCategoryParam() {
		Schema.PicklistEntry result;
		String cParam = ApexPages.currentPage().getParameters().get('c');
		if (String.isNotBlank(cParam)) {
			String categoryNotFiltred = cParam.toLowerCase();
			for (Schema.PicklistEntry pe : SObjectType.Asset__c.fields.Category__c.getPicklistValues()) {
				if (pe.getValue().toLowerCase() == categoryNotFiltred) {
					result = pe;
					break;
				}
			}
		}
		return result;
	}

	// EDIT/VIEW MODE

	public Asset__c tesla { get; set; } //instantiate object record
	public Blob imgBody { get; set; } 
	public String imgFileName { get; set; }
	public String imgContentType { get; set; }
	public String linkText { get; set; }
	public LPFieldLayout flayout { get; set; }
	public Boolean isDel { get { return isDel == true; } set; }
	public String attachmentId { get; set; }
	public Boolean fileIndicator { get; set; }
	public String LBL_Welcome_to_Portfolio {
		get {
			return String.format(Label.LBL_Welcome_to_Portfolio_c, new List<String>{ PortfolioOwnerName });
		}
	}

	/* controls LPAssetEdit.page */
	public void initFromEdit() {
		init();
	}

	public LPLearnerProfileController.EliforpPage efp { get; set; }

	/* controls LPAssetDetail.page */
	public void initFromView() {
		init();
		efp = new LPLearnerProfileController.EliforpPage(tesla);
	}

	private void init() {
		lpMode = String.isNotBlank(ApexPages.currentPage().getParameters().get('lp'));

		List<Asset__c> check = [SELECT Id, IsDeleted FROM Asset__c WHERE Id = :stdctrl.getId() ALL ROWS];
		isDel = (!check.isEmpty() && check[0].IsDeleted == false) ? false : true;
		tesla = isDel ? new Asset__c() : (Asset__c)stdctrl.getRecord();

		/* using Notes and Attachments to handle upload of Content */
		List<String> hardFields = new List<String> {
			'Id', 'Name', 'Link__c', 'Category__c', 'Status__c',
			'(SELECT Id, IsNote, Title FROM NotesAndAttachments WHERE IsNote = false ORDER BY CreatedDate DESC LIMIT 1)'
		};

		/* Fields displayed on LPAssetEdit and LPAssetDetail */
		flayout = new LPFieldLayout(
			tesla.Id,
			SObjectType.Asset__c.FieldSets.Edit_Assets,
			SObjectType.Asset__c,
			hardFields,
			LPUtils.getPackagePrefix()
		);

		/* After save, display LPAssetDetail */
		if (tesla.Id != NULL) {
			tesla = (Asset__c)flayout.getRecord();
		}
		/* if Category NULL, return error message */
		else {
			Schema.PicklistEntry pe2 = getCategoryParam();
			if (pe2 != NULL) {
				tesla.Category__c = pe2.getValue();
			}
		}
	}

	public String getDelRedirectParam() {
		String c = (tesla == NULL) ? '' : tesla.Category__c;
		String lp = lpMode ? ApexPages.currentPage().getParameters().get('lp') : '';
		return ((String.isNotBlank(c)) ? 'c='+c : '') + ((String.isNotBlank(lp) && String.isNotBlank(lp)) ? '&' : '') + ((String.isNotBlank(lp)) ? 'lp='+lp : '');
	}

	
	public PageReference saveAsset() {
		PageReference pr;
		if (tesla.Id == NULL && tesla.User__c == NULL) {
			tesla.User__c = UserInfo.getUserId();
		}
		try {
			/* append http, etc to links */
			if (String.isNotBlank(linkText)) {
				tesla.Link__c = (!linkText.startsWith('http://') && !linkText.startsWith('https://')) ? ('http://' + linkText) : linkText;
				upsert tesla;
			}
			else if (imgBody != NULL && String.isNotBlank(imgFileName)) {
				tesla.Link__c = NULL;
				upsert tesla;
			/* creates Attachment to Asset__c record */
				insert new Attachment(
					Name = imgFileName,
					Body = imgBody,
					ParentId = tesla.Id,
					ContentType = imgContentType
				);
			}
			/* Attachment already exists */
			else if (attachmentId != 'false' && String.isNotBlank(attachmentId)) {
				tesla.Link__c = NULL;
				upsert tesla;

				List<Attachment> acList = [SELECT Id, Name, Body, ContentType, ParentId FROM Attachment WHERE Id = :attachmentId];
				if (acList.size() > 0) {
					Attachment ac = acList[0];
					insert new Attachment(
						Name = ac.Name,
						Body = ac.Body,
						ParentId = tesla.Id,
						ContentType = ac.ContentType,
						Description = 'CreatedByAsset'
					);
					
					//LP-87 ----->
					try {
						delete [SELECT Id FROM Asset__c WHERE Id = :ac.ParentId];
					}
					catch(Exception e) {
						System.debug('Delete problem!');
					}
					//LP-87 <-----
				}
			}
			else if (fileIndicator) {
				tesla.Link__c = NULL;
				upsert tesla;
			}
			else {
				upsert tesla;
			}
			pr = Page.LPAssetDetail;
			pr.getParameters().put('Id', tesla.Id);
			pr.setRedirect(true);
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return pr;
	}

	public PageReference clearAttach() {
		// delete asset when "cancel" 
		Cookie createdAsset = ApexPages.currentPage().getCookies().get('CreatedAsset');

		if (createdAsset != null) {
			String createdAssetValue = createdAsset.getValue();
			if (String.isNotBlank(createdAssetValue) || createdAssetValue != 'null') {
				createdAssetValue = String.escapeSingleQuotes(createdAssetValue);
				try {
					delete [SELECT Id FROM Attachment WHERE Id = :createdAssetValue];
				} catch(Exception e) {
					System.debug('Delete problem! ' + e);
				}
			}
		}
		//LP-87 -----> Deletes Asset__c record
		Cookie assetCook = ApexPages.currentPage().getCookies().get('AssetIdToDelete');

		if (assetCook != null) {
			String cookieValue = assetCook.getValue();
			if (String.isNotBlank(cookieValue) || cookieValue != 'null') {
				String escapeCookieValue = String.escapeSingleQuotes(cookieValue);
				try {
					delete [SELECT Id FROM Asset__c WHERE Id = :escapeCookieValue];
				}
				catch(Exception e) {
					System.debug('Delete problem! ' + e);
				}
			}
		}
		/* redirects to LPAssets */
		String retURLParametr = ApexPages.currentPage().getParameters().get('retURL');
		if (String.isNotBlank(retURLParametr)) {
			PageReference pr = new PageReference(retURLParametr);
			pr.setRedirect(true);
			return pr;
		}
		PageReference pr = Page.LPAssets;
		pr.setRedirect(true);
		return pr;
		//LP-87 <-----
	}

	public void clearAttachSave() {
		clearAttachContact();
		clearAttachAsset(false);
	}

	public void clearAttachContact() {
		String contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()][0].ContactId;
		delete [SELECT Id FROM Attachment WHERE Description = 'CreatedByAsset' AND ParentId = :contactId];
	}

	public void clearAttachAsset(Boolean cancel) {
		List<Attachment> attachToDelete;
		Attachment attachWithDescription;
		attachToDelete = [SELECT Id FROM Attachment WHERE Description = 'CreatedByAsset' AND ParentId = :tesla.Id ORDER BY CreatedDate DESC];
		if (attachToDelete.size() > 0) {
			if (!cancel && String.isBlank(linkText)) {
				attachWithDescription = attachToDelete[0];
				attachWithDescription.description = '';
				update attachWithDescription;
				attachToDelete.remove(0);
			}
			delete attachToDelete;
		}
	}

	/* displays the image for ePortfolio shareable side */
	public static String getHeroImageId() {
		return LP_Template_Settings__c.getInstance().Hero_Image__c;
	}
	public static Boolean getHasCustomHeroImage() {
		return String.isNotBlank(LP_Template_Settings__c.getInstance().Hero_Image__c);
	}

	/* called from Save & Add button on LPLearnerProfileEdit */
	public PageReference saveAndAddAsset() {
		Boolean createMode = getShowCreateAddBtn();
		PageReference pr = saveAsset();
		if (createMode && tesla.Status__c != 'Inactive') {
			Id lpParamId = Id.valueOf(ApexPages.currentPage().getParameters().get('lp'));
			insert new Asset_Learner_Profile__c(
				Asset__c = tesla.Id,
				Learner_Profile__c = lpParamId
			);
			String retURLParametr = ApexPages.currentPage().getParameters().get('retUrl');
			if (String.isBlank(retURLParametr)) {
				pr = Page.LPAssets;
				pr.getParameters().put('lp', lpParamId);
				pr.setRedirect(true);
			}
			else {
				pr = new PageReference(retURLParametr);
			}
		}
		return pr;
	}

	public void submitAddRemoveLP() {
		Set<Id> deleteAssetProfile = new Set<Id>();
		List<Asset_Learner_Profile__c> createAssetProfile = new List<Asset_Learner_Profile__c>();
		for (LPLearnerProfileController.Eliforp elItem : efp.lps) {
			if (elItem.initialyChecked != elItem.checked) {
				if (elItem.checked) {
					createAssetProfile.add(
						new Asset_Learner_Profile__c(
							Asset__c = tesla.Id,
							Learner_Profile__c = elItem.Id
						)
					);
				}
				else {
					deleteAssetProfile.add(elItem.Id);
				}
			}
		}
		if (createAssetProfile.size() > 0) {
			insert createAssetProfile;
		}
		if (deleteAssetProfile.size() > 0) {
			delete [SELECT Id FROM Asset_Learner_Profile__c WHERE Asset__c = :tesla.Id AND Learner_Profile__c IN :deleteAssetProfile];
		}
		initFromView();
	}

	public Boolean getShowMyLPbtn() {
		return SObjectType.Asset_Learner_Profile__c.isCreateable() && tesla.Status__c != 'Inactive';
	}

	public String getLearnerProfileName() {
		Id lpParamId = Id.valueOf(ApexPages.currentPage().getParameters().get('lp'));
		return getShowCreateAddBtn() ? [SELECT Name FROM Learner_Profile__c WHERE Id = :lpParamId].Name : '';
	}

	public Boolean getShowCreateAddBtn() {
		return lpMode && tesla.Id == NULL;
	}

	public List<String> getAssetLink() {
		List<String> resultList = new List<String> { '', '', 'fa-file-o' };
		if (String.isNotBlank(tesla.Link__c)) {
			resultList = new List<String> { tesla.Link__c, tesla.Link__c, 'fa-link' };
		}
		else if (tesla.NotesAndAttachments.size() > 0) {
			String[] parts = tesla.NotesAndAttachments[0].Title.split('\\.');
			String ext = parts[parts.size() - 1].toLowerCase();
			//ext = !CommunitySearchController.AWESOME_FILE_TYPES.containsKey(ext) ? 'fa-file-o' : CommunitySearchController.AWESOME_FILE_TYPES.get(ext);
			resultList = new List<String> {
				tesla.NotesAndAttachments[0].Title,
				LPUtils.checkUrl('/servlet/servlet.FileDownload?file=' + tesla.NotesAndAttachments[0].Id),
				'fa-file-o'
			};
		}
		return resultList;
	}

	public PageReference deleteAsset() {
		PageReference pr;
		try {
			delete tesla;
			pr = Page.LPAssets;
			if (lpMode) {
				pr.getParameters().put('lp', Id.valueOf(ApexPages.currentPage().getParameters().get('lp')));
			}
			pr.getParameters().put('c', tesla.Category__c);
			pr.setRedirect(true);
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return pr;
	}

	public String getDeleteConfirmMessage() {
		Boolean acdc = false;
		for (LPLearnerProfileController.Eliforp eleItem : efp.lps) {
			acdc = (eleItem.checked == true) ? true : acdc;
		}
		return acdc ? Label.LBL_Delete_Asset : Label.LBL_Delete_Asset_message;
	}

	public Boolean getInitialActiveStatus() {
		return tesla.Status__c == 'Active';
	}

	// LIST MODE 

	private Boolean listMode;
	private Boolean categoryMode;
	private final static String ALIAS_PARAM_DIVIDER = '?u=';

	public Boolean lpMode { get { return lpMode == NULL ? false : lpMode; } set; }
	public Boolean wrongProfile { get { return wrongProfile == NULL ? false : wrongProfile; } set; }
	public transient Learner_Profile__c currentLearnerProfile { get; set; }

	public void initFromList() {
		listMode = getCategoryParam() == NULL;
		categoryMode = !listMode;
		String lpParam = ApexPages.currentPage().getParameters().get('lp');
		lpMode = String.isNotBlank(lpParam);
		currentLearnerProfile = new Learner_Profile__c();
		if (lpMode) {
			String escapedParam = String.escapeSingleQuotes(lpParam);
			List<Learner_Profile__c> checkLPlist = [
				SELECT Id, Status__c, Name, Description__c
				FROM Learner_Profile__c
				WHERE Id = :String.escapeSingleQuotes(lpParam)
					AND OwnerId = :UserInfo.getUserId()
			];
			wrongProfile = checkLPlist.size() == 0;
			currentLearnerProfile = wrongProfile ? new Learner_Profile__c() : checkLPlist[0];
		}
		
	}

	public Boolean getInactiveProfile() {
		Set<String> activeProfileSet = new Set<String> { 'Active', 'Draft' };
		return lpMode && !activeProfileSet.contains(currentLearnerProfile.Status__c);
	}

	public String getLPStatusColorStyle() {
		Map<String, String> tm = new Map<String, String> { 'Active' => 'text-success', 'Draft' => 'text-warning', 'Inactive' => 'text-danger' };
		return tm.get(currentLearnerProfile.Status__c);
	}

	public String getLearnerProfilePageLink() {
		return LPLearnerProfileController.BASE_LP_LINK + currentLearnerProfile.Id;
	}

	public Boolean getShowLPbtns() {
		return lpMode && !categoryMode;
	}

	public Boolean getAddFromCategoryBtn() {
		return lpMode && categoryMode && SObjectType.Asset_Learner_Profile__c.isCreateable();
	}

	public String getUrlForAddFromCategory() {
		return prepareUrl(Page.LPMyAssets.getUrl()) + addCategoryLPParam('?');
	}

	public String getUrlForNewAsset() {
		return prepareUrl(Page.LPAssetEdit.getUrl())
				+ '?retURL=' + EncodingUtil.urlEncode(prepareUrl(Page.LPAssets.getUrl() + addCategoryLPParam('?')), 'UTF-8')
				+ addCategoryLPParam('&');
	}

	public String getUrlForEditAsset() {
		return prepareUrl(Page.LPAssetEdit.getUrl())
				+ '?id=' + tesla.Id
				+ '&retURL=' + EncodingUtil.urlEncode(prepareUrl(Page.LPAssetDetail.getUrl()) + '?id=' + tesla.Id, 'UTF-8');
	}

	public String getUrlForEditLearnerProfile() {
		String lpId = ApexPages.currentPage().getParameters().get('lp');
		return prepareUrl(Page.LPLearnerProfileEdit.getUrl())
				+ '?id=' + lpId
				+ '&retURL=' + EncodingUtil.urlEncode(prepareUrl(Page.LPAssets.getUrl()) + '?lp=' + lpId, 'UTF-8');
	}

	public String getLearnerProfileLink() {
		return lpMode ? ('&lp=' + String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('lp'))) : '';
	}

	private static String prepareUrl(String inUncouthUrl) {
		return inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/');
	}

	private String addCategoryLPParam(String inGlue) {
		String result = '';
		String cp = ApexPages.currentPage().getParameters().get('c');
		if (String.isNotBlank(cp)) {
			result += inGlue +'c=' + EncodingUtil.urlEncode(cp, 'UTF-8');
			inGlue = '&';
		}
		String lpp = ApexPages.currentPage().getParameters().get('lp');
		if (String.isNotBlank(lpp)) {
			result += inGlue +'lp=' + lpp;
		}
		return result;
	}

	public List<Yrogetac> getCategories() {
		List<Yrogetac> resultList = new List<Yrogetac>();
		if (listMode == true && !wrongProfile) {
			String yQuery = 'SELECT COUNT(Id) Counter, Category__c Cat FROM Asset__c WHERE User__c =\'' + UserInfo.getUserId() + '\'';
			if (lpMode) {
				yQuery += ' AND Id IN (SELECT Asset__c FROM Asset_Learner_Profile__c WHERE Learner_Profile__c = \'';
				yQuery += String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('lp')) + '\')';
			}
			yQuery += 'GROUP BY Category__c ORDER BY Category__c';
			Map<String, Yrogetac> filledCategoriesMap = new Map<String, Yrogetac>();
			for (AggregateResult arItem : Database.query(yQuery)) {
				String tc = (String)arItem.get('Cat');
				filledCategoriesMap.put((String.isBlank(tc) ? 'none' : tc.toLowerCase()), new Yrogetac(arItem));
			}
			for (Schema.PicklistEntry pe : SObjectType.Asset__c.fields.Category__c.getPicklistValues()) {
				String tc2 = pe.getValue().toLowerCase();
				resultList.add(filledCategoriesMap.containsKey(tc2) ? filledCategoriesMap.get(tc2) : new Yrogetac(pe.getValue()));
			}
		}
		return resultList;
	}

	public List<Tessa> getAssets() {
		List<Tessa> resultList = new List<Tessa>();
		if (categoryMode == true && !wrongProfile) {
			String aQuery = 'SELECT Id, Name, Link__c, Description__c, Type__c, Status__c, CreatedDate, (SELECT Id, Name, BodyLength FROM Attachments ORDER BY CreatedDate DESC LIMIT 1)';
			aQuery += ' FROM Asset__c WHERE Category__c = \'' + String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('c')) + '\'';
			aQuery += ' AND User__c =\'' + UserInfo.getUserId() + '\'';
			if (lpMode) {
				aQuery += ' AND Id IN (SELECT Asset__c FROM Asset_Learner_Profile__c WHERE Learner_Profile__c = \'';
				aQuery += String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('lp')) + '\')';
			}
			for (Asset__c aItem : Database.query(aQuery)) {
				resultList.add(new Tessa(aItem));
			}
		}
		return resultList;
	}

	private static Map<String, String> AWESOME_FILE_TYPES = new Map<String, String> {
		'link' => 'fa-link', 'xls' => 'fa-file-excel-o', 'xlsx' => 'fa-file-excel-o', 'pdf' => 'fa-file-pdf-o',
		'doc' => 'fa-file-word-o', 'docx' => 'fa-file-word-o', 'ppt' => 'fa-file-pdf-o', 'pptx' => 'fa-file-pdf-o',
		'txt' => 'fa-file-text-o', 'png' => 'fa-file-image-o', 'gif' => 'fa-file-image-o', 'jpeg' => 'fa-file-image-o',
		'jpg' => 'fa-file-image-o', 'bmp' => 'fa-file-image-o'
	};

	// PAGE MODE

	public Boolean portfolioFound { get; set; }
	public String portfolioOwnerName { get; set; }
	public String portfolioDescription { get; set; }

	public void initFromPage() {
		try {
			Id lpParamId = Id.valueOf(ApexPages.currentPage().getParameters().get('lp'));
			Learner_Profile__c checklp = [
				SELECT Id, Description__c, Owner.Id, Owner.Name
				FROM Learner_Profile__c
				WHERE Id = :lpParamId
					AND (Status__c = 'Active' OR (Status__c = 'Draft' AND OwnerId = :UserInfo.getUserId()))
			];

			List<User> uList = [
				SELECT Id, Contact.Id, Contact.FirstName, Contact.LastName
				FROM User
				WHERE Id = :checklp.Owner.Id
					AND ContactId != null
			];
			portfolioOwnerName = uList.isEmpty() ? checklp.Owner.Name : uList[0].Contact.FirstName + ' ' + uList[0].Contact.LastName;
			portfolioDescription = checklp.Description__c;
			portfolioFound = true;
		}
		catch (Exception e) {
			portfolioFound = false;
		}
	}

	/* grabs all the populated Categories for a particular ePortfolio */
	public List<Yrogetac> getCategoriesWithAssets() {
		List<Yrogetac> resultList = new List<Yrogetac>();
		if (portfolioFound) {
			Map<String, Yrogetac> assemblyCategoryMap = new Map<String, Yrogetac>();
			Id lpParamId = Id.valueOf(ApexPages.currentPage().getParameters().get('lp'));
			for (Asset__c aItem : [
						SELECT Id, Name, Link__c, Description__c, Type__c, Status__c, Category__c, CreatedDate,
							(SELECT Id, Name, BodyLength FROM Attachments ORDER BY CreatedDate DESC LIMIT 1)
						FROM Asset__c
						WHERE Id IN (SELECT Asset__c FROM Asset_Learner_Profile__c WHERE Learner_Profile__c = :lpParamId)
				]) {

				String catUnique = String.isBlank(aItem.Category__c) ? 'none' : aItem.Category__c;
				catUnique = catUnique.replace(' ', '').toLowerCase();
				if (!assemblyCategoryMap.containsKey(catUnique)) {
					assemblyCategoryMap.put(catUnique, new Yrogetac(aItem.Category__c, catUnique));
				}
				assemblyCategoryMap.get(catUnique).assets.add(new Tessa(aItem));
			}
			for (Schema.PicklistEntry pe : SObjectType.Asset__c.fields.Category__c.getPicklistValues()) {
				String tc3 = pe.getValue().replace(' ','').toLowerCase();
				if (assemblyCategoryMap.containsKey(tc3)) {
					resultList.add(assemblyCategoryMap.get(tc3));
				}
			}
		}
		return resultList;
	}

	public String getLogoUrl() {
		LP_Template_Settings__c lpts = LP_Template_Settings__c.getOrgDefaults();
		return (lpts == NULL || String.isBlank(lpts.Header_Logo__c)) ? NULL : lpts.Header_Logo__c;
	}

	public PageReference getSiteTemplatePage() {
		return LPUtils.getSiteTemplatePage();
	}

	// WRAPPER CLASSES
	/* grabs Asset__c records for display on Category pages */
	public class Tessa {
		public String id { get; set; }
		public String name { get; set; }
		public String atype { get; set; }
		public String link { get; set; }
		public String description { get; set; }
		public String icon { get; set; }
		public String size { get; set; }
		public String file { get; set; }
		public String status { get; set; }
		public String dshot { get; set; }

		public Tessa(Asset__c ina) {
			id = ina.Id;
			name = ina.Name;
			atype = ina.Type__c;
			description = ina.Description__c;
			dshot = String.isBlank(description) ? '' : description.abbreviate(32);
			file = ina.Status__c == 'Inactive' ? 'f-txt' : 'f-docx';
			status = ina.Status__c;
			if (String.isNotBlank(ina.Link__c)) {
				icon = 'fa-link';
				link = ina.Link__c;
			}
			else if (ina.Attachments.size() > 0) {
				String[] parts = ina.Attachments[0].Name.split('\\.');
				String ext = parts[parts.size() - 1].toLowerCase();
				icon = !AWESOME_FILE_TYPES.containsKey(ext) ? 'fa-file-o' : AWESOME_FILE_TYPES.get(ext);
				size = LPUtils.convertFileSize(ina.Attachments[0].BodyLength);
				link = LPUtils.checkUrl('/servlet/servlet.FileDownload?file=' + ina.Attachments[0].Id);
			}
			else {
				link = '#';
				icon = 'fa-file-o';
			}
		}
	}

	/* grabs lists from above to display count */
	public class Yrogetac {
		public String name { get; set; }
		public Integer counter { get; set; }
		public List<Tessa> assets { get; set; }
		public String catid { get; set; }

		public Yrogetac(AggregateResult inar) {
			name = (String)inar.get('Cat');
			counter = (Integer)inar.get('Counter');
		}

		public Yrogetac(String inc) {
			name = inc;
			counter = 0;
		}

		public Yrogetac(String inc, String inid) {
			name = inc;
			catid = inid;
			assets = new List<Tessa>();
		}

		public String getItemString() {
			List<String> parts = Label.LBL_Item_Items.split(';');
			String single = parts[0];
			String plural = parts.size() > 1 ? parts[1] : parts[0];
			return String.valueOf(counter) + ' ' + (counter == 1 ? single : plural);
		}
	}
	
		/* LIST VIEW */
	public class ListView{
		public List<String> catList {get; set;}
		//uses unique category__c as key and map of assets for that category
		public Map<String, Map<Id,Asset__c>> assetCatMap {get; set;}
		//temp asset Map
		public Map<Id, Asset__c>  assetMap {get; set;}
		//list of all assets
		public List<Asset__c> assetList {get; set;}
		//tracks the current Category__c to know when it changes
		public String currentCat {get; set;}
	
	public ListView(){
		//converts picklist into list of strings
		catList = new List<String>();
			Schema.DescribeFieldResult fieldResult = Asset__c.Category__c.getDescribe();
			System.debug(fieldResult);
			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
			System.debug('--ple-->> ' + ple);
			for(Schema.PicklistEntry f : ple){
				catList.add(f.getLabel());
			}
			
			assetList = [select Name, Category__c, LastModifiedDate from Asset__c where OwnerId = :UserInfo.getUserId() order by Category__c]; //get records
			assetCatMap = new Map<String, Map<Id,Asset__c>>();
			assetMap = new Map<Id, Asset__c>();
		
			currentCat = null;
			//add catList values to map
			for(String c : catList){
				assetCatMap.put(c, null);
		}
	
			//save currentCat of first asset
			for(Integer i = 0; i< assetList.size(); i++){
				if(currentCat == null){
					currentCat = assetList[i].Category__c;
				}
				
				//if category__c has changed or if it's the last record, save the assetMap for the category__c
				if(currentCat != assetList[i].Category__c || assetList.size() == i+1){
					assetCatMap.put(currentCat, assetMap.clone());
					assetMap.clear();
					currentCat = assetList[i].Category__c;
				}
				assetMap.put(assetList[i].Id, assetList[i]);
			}
			//adds categories with null lists
			for(String c :catList){
				if(assetCatMap.get(c) == null){
					assetCatMap.put(c, new Map<Id, Asset__c>());
				}
			}
			
		}
	}
}