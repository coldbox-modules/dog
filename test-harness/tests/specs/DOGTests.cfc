component extends='coldbox.system.testing.BaseTestCase' appMapping='/root'{

/*********************************** LIFE CYCLE Methods ***********************************/

	this.unloadColdBox = true;
	this.testContainerName = "test-container-" & getTickCount();

	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();		
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
		super.afterAll();
	}

/*********************************** BDD SUITES ***********************************/

	function run(){
		
		describe( 'DOG Module', function(){


			beforeEach(function( currentSpec ){
				setup();
			});

			describe( 'Client management', function(){
					
				it( 'should register library', function(){
					var dog = getLib();
					expect( dog ).toBeComponent();
				});

			});
			
			describe( 'Fedex', function(){
					
				it( 'can check shipment', function(){
					var response = getLib().fetchFedEx( "231300687629630", "structure" );
					expect( response ).toBeStruct();
				});

			});

			describe( 'UPS', function(){
					
				it( 'can check shipment', function(){
					var response = getLib().fetchUPS( "123456789012", "structure" );
					
					expect( response ).toBeStruct();
				});

			});

			describe( 'Dayton Freight', function(){
					
				it( 'can check shipment', function(){
					var response = getLib().fetchDaytonFreight( "1234567890", "structure" );
					
					expect( response ).toBeStruct();
				});

			});

			xdescribe( 'RLC', function(){
					
				it( 'can check shipment', function(){
					var response = getLib().fetchRLC( "1234567890", "structure" );
					
					expect( response ).toBeStruct();
				});

			});

			// SITE NO LONGER AVAILABLE
			// displays when you hit the API
			xdescribe( 'Holland', function(){
					
				it( 'can check shipment', function(){
					var response = getLib().fetchHolland( "1234567890", "structure" );
					
					expect( response ).toBeStruct();
				});

			});

			describe( 'YRC', function(){
					
				it( 'can check shipment', function(){
					var response = getLib().fetchYRC( "1234567890", "structure" );
					
					expect( response ).toBeStruct();
				});

			});

			xdescribe( 'Aftership', function(){
					
				it( 'can check shipment', function(){
					var response = getLib().fetchAftership( "1234567890", "structure" );
					
					expect( response ).toBeStruct();
				});

			});

			describe( 'XPO Logistics', function(){

				it( 'can check shipment', function(){
					var response = getLib().fetchXPOLogistics( "1234567890", "structure" );
					
					expect( response ).toBeStruct();
				});

			});

			describe( 'Uber Freight', function(){

				it( 'can check shipment', function(){
					var response = getLib().fetchUberFreight( "1234567890", "structure" );
					
					expect( response ).toBeStruct();
				});

			});
		});
	}

	private function getLib( name='deliveryObservationGadget@dog' ){
		return getWireBox().getInstance( name );
	}

}