@isTest 
private class LPTests {

	static testMethod void test_LPAssetController() {
		Account acc = new Account(Name='testAccount');
		insert acc;
		Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc67@testdomain.com', AccountId=acc.Id);
		insert con;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'Learner Profile User'];
		User u = new User(alias='alias', email='testc67@testdomain.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf67@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname76', ContactId=con.Id);
		insert u;

		System.runAs(u) {
			LPAssetController lpac = new LPAssetController(new ApexPages.StandardController(new Asset__c()));
			lpac.getPrefix();
			lpac.initFromEdit();
			lpac.tesla.Name = 't';
			lpac.tesla.Category__c = 'Resume';
			lpac.linkText = 'www.tut.by';
			lpac.saveAsset();
			lpac.initFromEdit();
			List<String> tl = lpac.getAssetLink();
			System.assert(tl.size() > 0, true);
			lpac.getUrlForEditAsset();
			LPAssetController lpac3 = new LPAssetController();
			lpac3.initFromList();
			List<LPAssetController.Yrogetac> gh = lpac3.getCategories();
			String sm = gh.size() > 0 ? gh[0].getItemString() : '';
			
			ApexPages.currentPage().getParameters().put('c','Resume');
			LPAssetController lpac2 = new LPAssetController(new ApexPages.StandardController(new Asset__c()));
			lpac2.initFromEdit();
			lpac2.tesla.Name = 't2';
			lpac2.imgBody = EncodingUtil.base64Decode('/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAAMABADASIAAhEBAxEB/8QAFgABAQEAAAAAAAAAAAAAAAAAAQAC/8QAGRAAAwADAAAAAAAAAAAAAAAAAAERElFx/8QAFAEBAAAAAAAAAAAAAAAAAAAAAP/EABQRAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhEDEQA/ADF6KOGp0IB//9k=');
			lpac2.imgFileName = 'ifn.jpg';
			lpac2.imgContentType = 'image/jpg';
			lpac2.saveAsset();
			lpac2.initFromEdit();
			lpac2.clearAttachContact();
			lpac2.clearAttach();
			lpac2.getInitialActiveStatus();
			lpac2.getSiteTemplatePage();
			System.debug('\n**:' + json.serialize(lpac2.tesla));
			List<String> tl2 = lpac2.getAssetLink();
			System.assert(tl2.size() > 0, true);

			Learner_Profile__c lp = new Learner_Profile__c(Name='lpname',Status__c='Active');
			insert lp;
			ApexPages.currentPage().getParameters().put('lp',lp.Id);
			LPAssetController lpac6 = new LPAssetController(new ApexPages.StandardController(new Asset__c()));
			lpac6.initFromEdit();
			lpac6.tesla.Name = 't';
			lpac6.tesla.Category__c = 'Resume';
			System.assert(lpac6.getDelRedirectParam() != NULL);
			lpac6.linkText = 'www.tut.by';
			lpac6.saveAndAddAsset();
			lpac6.clearAttachAsset(true);

			LPAssetController lpac4 = new LPAssetController();
			lpac4.initFromList();
			lpac4.getAssets();
			lpac4.getUrlForNewAsset();
			lpac4.getInactiveProfile();
			lpac4.getLearnerProfilePageLink();
			lpac4.getLPStatusColorStyle();
			lpac4.getShowLPbtns();
			lpac4.getUrlForEditLearnerProfile();
			lpac4.getLearnerProfileLink();
			lpac4.getAddFromCategoryBtn();
			lpac4.getUrlForAddFromCategory();

			LPAssetController lpac7 = new LPAssetController(new ApexPages.StandardController(lpac6.tesla));
			lpac7.initFromView();
			lpac7.getShowMyLPbtn();
			lpac7.getLearnerProfileName();
			lpac7.efp.lps[0].checked = false;
			lpac7.submitAddRemoveLP();
			lpac7.getDeleteConfirmMessage();
			PageReference pr = lpac7.deleteAsset();
			System.assert(pr != NULL, true);

			LPAssetController lpac5 = new LPAssetController();
			lpac5.initFromPage();
			lpac5.getCategoriesWithAssets();
			lpac5.getLogoUrl();

			LPAssetController.getHeroImageId();
			LPAssetController.getHasCustomHeroImage();
		}
	}

	/*static testMethod void test_LPSignController() {
		Account acc = new Account(Name='testAccount');
		insert acc;
		ApexPages.currentPage().getParameters().put('code',acc.Id);
		LPSignController lpsc = new LPSignController();
		lpsc.initFromRegistration();
		lpsc.username = 'un@example.com';
		lpsc.firstname = 'fn';
		lpsc.lastname = 'ln';
		lpsc.email = 'un@example.com';
		lpsc.password = 'test234Passwrd';
		lpsc.createUser();
		lpsc.login();
		lpsc.emailToReset = lpsc.email;
		lpsc.resetPasswordMode = 2;
		lpsc.resetPasswordAction();
		lpsc.oldPassword = lpsc.password;
		lpsc.password = 'test236Passwrd';
		lpsc.verifyPassword = lpsc.password;
		lpsc.changePassword();
		lpsc.getSiteTemplatePage();
	}*/

	static testMethod void test_LPUtils() {
		LPUtils.convertFileSize(1048575);
		LPUtils.convertFileSize(1073741823);
		LPUtils.getSiteTemplatePage();
		LPUtils.checkUrl('someUrl');
		System.assert(LPUtils.convertFileSize(1073741824) == '1.00 GB', true);
	}

	static testMethod void test_Labels() {
		String addOrRemoveFromMyAssets = Label.BTN_Add_or_Remove_from_My_Assets;
		String addRemoveFromMyAssetsInThisCategory = Label.BTN_Add_Remove_from_MyAssets_in_this_Category;
		String saveAddLearnerProfile = Label.BTN_Save_Add_Learner_Profile;
		String uploadAsset = Label.BTN_Upload_Asset;
		String passwordNoMatch = Label.ERR_Password_no_match;
		String uploadOnlyOneFile = Label.ERR_Upload_Only_One_File;
		String active = Label.LBL_Active;
		String addRemoveAsset = Label.LBL_Add_Remove_Asset;
		String addRemoveLearnerProfileTitle = Label.LBL_Add_Remove_Learner_Profile_Title;
		String adminTitlePage = Label.LBL_Admin_Title_Page;
		String allAssets = Label.LBL_All_Assets;
		String allLearnerProfiles = Label.LBL_All_Learner_Profiles;
		String assetDetailTitle = Label.LBL_Asset_Detail_Title;
		String assetWillNotBeSaved = Label.LBL_Asset_Will_Not_Be_Saved;
		String deselectAll = Label.LBL_Deselect_All;
		String dragAndDropFilesHere = Label.LBL_Drag_and_Drop_Files_here;
		String editAssetRequiredField = Label.LBL_Edit_Asset_Required_Field;
		String editAssetSelectResource = Label.LBL_Edit_Asset_Select_Resource;
		String emailForReset = Label.LBL_Email_for_reset;
		String fileBrowserPageTitle = Label.LBL_File_Browser_Page_Title;
		String fileUploadSizeLimit = Label.LBL_File_Upload_Size_Limit;
		String learnerProflieMessage1 = Label.LBL_Learner_Proflie_Message_1;
		String link = Label.LBL_Link;
		String lPLink = Label.LBL_LP_Link;
		String myLearnerProfiles = Label.LBL_My_Learner_Profiles;
		String noAssetsFound = Label.LBL_No_assets_found;
		String noPortfolio = Label.LBL_No_Portfolio;
		String pageTitle = Label.LBL_Page_Title;
		String pickNewPassword = Label.LBL_Pick_new_password;
		String saveAddLearnerProfileMessage = Label.LBL_Save_Add_Learner_Profile_Message;
		String searchAsset = Label.LBL_Search_Asset;
		String selectAll = Label.LBL_Select_All;
		String selectFilesFromComputer = Label.LBL_Select_Files_from_Computer;
		String showHideAll = Label.LBL_Show_Hide_All;
		String signIn = Label.LBL_Sign_in;
		String signInEmail = Label.LBL_Sign_In_Email;
		String signInPassword = Label.LBL_Sign_In_Password;
		String signInTitle = Label.LBL_Sign_In_Title;
		String signOut = Label.LBL_Sign_Out;
		String signUp = Label.LBL_Sign_up;
		String signUpFirstName = Label.LBL_Sign_up_First_Name;
		String signUpHaveAccount = Label.LBL_Sign_up_Have_Account;
		String signUpLastName = Label.LBL_Sign_up_Last_Name;
		String signUpTitle = Label.LBL_Sign_up_Title;
		String typeItAgain = Label.LBL_Type_it_again;
		String upload = Label.LBL_Upload;
		String uploadFile = Label.LBL_Upload_File;
		String uploadOneFile = Label.LBL_Upload_One_File;
		String url = Label.LBL_URL;
	}

	static testMethod void test_LPAdminController() {
		LPAdminController lpa = new LPAdminController();
		lpa.getFieldsTS();
		lpa.editTS();
		lpa.saveTS();
		lpa.cancelTS();
	}

	static testMethod void test_LPLearnerProfileController() {
		Account acc = new Account(Name='testAccount');
		insert acc;
		Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc67@testdomain.com', AccountId=acc.Id);
		insert con;
		Profile profile = [SELECT Id FROM Profile WHERE Name = 'Learner Profile User'];
		User u = new User(alias='alias', email='testc67@testdomain.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
			localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf67@testmail.com',
			FederationIdentifier='TestContactName.TestContactLastname76', ContactId=con.Id);
		insert u;

		System.runAs(u) {
			Asset__c a = new Asset__c(Name='tn',Status__c='Active',Category__c='Resume',User__c=u.Id);
			insert a;
			Learner_Profile__c lp = new Learner_Profile__c(Name='lpn',Status__c='Active');
			insert lp;
			ApexPages.currentPage().getParameters().put('lp',lp.Id);
			LPLearnerProfileController lplpc = new LPLearnerProfileController();
			lplpc.initFromAddRemove();
			lplpc.categories[0].assets[0].checked = true;
			lplpc.submitAddRemove();
			lplpc.cancelAddRemove();

			LPLearnerProfileController lplpc2 = new LPLearnerProfileController(new ApexPages.StandardController(lp));
			lplpc2.initFromEdit();
			lplpc2.saveLearnerProfile();
			lplpc2.getSiteTemplatePage();

			ApexPages.currentPage().getParameters().put('f','active');
			lplpc2.getLPcrowd();
		}
	}

	static testMethod void test_LPAssetTrigger() {
		Asset__c a = new Asset__c(Name='tn',Status__c='Active');
		insert a;
		Learner_Profile__c lp = new Learner_Profile__c(Name='lpn',Status__c='Active');
		insert lp;
		insert new Asset_Learner_Profile__c(Asset__c=a.Id, Learner_Profile__c=lp.Id);
		a.Status__c = 'Inactive';
		update a;
	}

	/*static testMethod void test_LPLeftPanelController() {
		LPLeftPanelController lpc = new LPLeftPanelController();
		String photoUrl = lpc.getProfilePhotoUrl();
		String expectedUrl = Schema.sObjectType.User.fields.getMap().containsKey('FullPhotoUrl') ? photoUrl : NULL;
		System.assert(photoUrl == expectedUrl);
		lpc.getCurrentContact(); 
	}*/

	static testMethod void test_LPHeaderController() {
		LPHeaderController controller = new LPHeaderController();
		String urlLogo = controller.getLogoUrl();
	}
	

	@IsTest(SeeAllData=true)
	static void test_LPMyPhotoController() {
		LPMyPhotoController controller = new LPMyPhotoController();
		String ctrPhotoUrl = controller.ctrPhotoUrl;
		//String actionPhotoLabel = controller.actionPhotoLabel; 
		Test.setCurrentPage(Page.LPMyPhoto);
		controller.photoName = 'name';
		controller.photoContentType = 'type';
		controller.cropX = '10';
		controller.cropY = '10';
		controller.cropSize = '10';
		Test.startTest();
		controller.photoaction();
		Test.stopTest();
	}
	
	/****DOR Test****/
	static testMethod void test_LPLeftPanelController() {
    LPLeftPanelController lpc = new LPLeftPanelController();
    lpc.getProfilePhotoUrl();
  }

  static testMethod void test_LPSignController() {

    //SignIn and Registration
    Account acc = new Account(Name='testAccount');
    insert acc;
    ApexPages.currentPage().getParameters().put('code',acc.Id);
    LPSignController lpsc = new LPSignController();
    lpsc.initFromRegistration();
    lpsc.username = 'un@example.com';
    lpsc.firstname = 'fn';
    lpsc.lastname = 'ln';
    lpsc.email = 'un@example.com';
    lpsc.password = 'test234Passwrd';
    lpsc.createCustomerUser(); 
    lpsc.emailToReset = lpsc.email;
    lpsc.resetPasswordMode = 2;
    lpsc.resetPasswordAction();
    lpsc.oldPassword = lpsc.password;
    lpsc.password = 'test236Passwrd';
    lpsc.verifyPassword = lpsc.password;
    lpsc.changePassword();
  }

 /* static testMethod void test_Labels() {
    String str = Label.LBL_Page_Title;
  }*/

  static testMethod void test_LPAboutMeAndTermsAndPhoto() {
    Account acc = new Account(Name='testAccount');
    insert acc;
    Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc67@testdomain.com', AccountId=acc.Id);
    insert con;
    Profile profile = [SELECT Id FROM Profile WHERE Name = 'Learner Profile Community User' LIMIT 1];
    User u = new User(alias='alias', email='testc67@testdomain.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
      localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='testc67@testdomain.com',
      FederationIdentifier='TestContactName.TestContactLastname67', ContactId=con.Id);
    insert u;


    System.runAs(u) {
      System.assert(LPSignController.getRegistrationPage(u.Id, false) != null);
      Contact regCon = LPSignController.getContactRegistration(u.Id);
      System.assert(LPSignController.needPhotoComplete(regCon));
      System.assert(!LPSignController.needTermsComplete(regCon, null));
      DOR_LP_Admin__c actualDA = new  DOR_LP_Admin__c(Terms_Body__c = 'body', 
              Terms_Status__c = 'Published', 
              Terms_Published_Date__c = Datetime.now(),
              Terms_Req_New_Signature__c = true,
              Name = 'name');
      insert actualDA;
      LPSignController lpsc = new LPSignController();

      //AboutMe
      lpsc.initFromAboutMe();
      lpsc.editAboutMe();
      for (LPFieldLayout.Field fld : lpsc.colayout.flds) {
        if (fld.tyrion) {
          if (fld.ftype == 'email') {
            lpsc.co.put(fld.name, 'testemail'+LPSignController.generateRandomString(9)+'@mail.com');
          }
          else if (fld.ftype == 'input' || fld.ftype == 'textarea') {
            lpsc.co.put(fld.name, LPSignController.generateRandomString(10));
          }
          else if (fld.ftype == 'checkbox') {
            lpsc.co.put(fld.name, true);
          }
          else if (fld.ftype == 'picklist') {
            lpsc.co.put(fld.name, (String)SObjectType.Contact.fields.getMap().get(fld.name).getDescribe().getPickListValues()[1].getValue());
          }
        }
      }
      lpsc.updateAboutMe();
      lpsc.editAboutMe();
      lpsc.cancelAboutMe();
      System.assert(LPSignController.getRegistrationPage(u.Id, false) != null);
      System.assert(LPSignController.getRegistrationPage(u.Id, true) != null);
      //TermsAndConditions
      lpsc.initFromTerms();
      lpsc.acceptTerms();
      regCon = LPSignController.getContactRegistration(u.Id);
      actualDA.Terms_Published_Date__c = Datetime.now();
      System.assert(LPSignController.needTermsComplete(regCon, actualDA));


      LPMyPhotoController lpmp = new LPMyPhotoController();
      Test.setCurrentPage(Page.LPMyPhoto);
      System.assert(lpmp.ctrPhotoUrl != null);
      Boolean tmp = lpmp.getRegMode();
      //ConnectApi.ChatterFeeds.setTestGetFeedItemsFromFeed(null, ConnectApi.FeedType.News, 'me', lpmp);
      //System.assert(lpmp.actionPhotoLabel != null);
      lpmp.photoName = 'PhotoName';
      lpmp.photoBody = Blob.valueOf('String o');
      lpmp.photoContentType = 'image/jpg';
      lpmp.cropX = '0';
      lpmp.cropY = '0';
      lpmp.cropSize = '100';
      lpmp.photoaction();
      regCon = LPSignController.getContactRegistration(u.Id);


      System.assert(lpmp.ctrPhotoUrl != null);
      lpmp.ctrPhotoUrl = 'https://salesforce.com/logo.png';
      System.assert(lpmp.ctrPhotoUrl != null);

      Test.setCurrentPage(Page.LPAboutMe);

      LPHeadDORController lphc = new LPHeadDORController();
     // System.assert(lphc.getAllowRedirect() == false);
      Test.setCurrentPage(Page.LPAssets);
      System.assert(lphc.getAllowRedirect() == true);
      System.assert(lphc.needAboutMe != null);
      System.assert(lphc.needTerms != null);



    }
  }
}