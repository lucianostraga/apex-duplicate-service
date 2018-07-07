({
	getDuplicates : function(component) {

        component.set('v.Dup_List', []);	
        component.set('v.isLoading', true);
        
        var action = component.get("c.getDuplicatesByRecordId");
        action.setParams({
            stringRecordId : component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if(component.isValid() && state === "SUCCESS") {                
                console.log(response.getReturnValue());
                component.set('v.Dup_List', response.getReturnValue());
                component.set('v.isLoading', false);
            } else {
                
                let errors = response.getError();
                let message = 'Unknown error'; // Default error message
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                console.error(message);
                component.set('v.isLoading', false);
            }
        });
        $A.enqueueAction(action);     
    },
    
})