function mapg
close all;
clear; clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
isTraining = false; %declare if it is training
toLandmarks = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath('../Basic Functions');
env = MAEnvironment;

alpha = 0.0025; %learning rate settings 
gamma = 1; %discount factor
maxItr = 3000;%maximum iterations for ending one episode

a1_p_estimator = PolicyEstimator(env,alpha);
a2_p_estimator = PolicyEstimator(env,alpha);
v_estimator = ValueEstimator(env,alpha*20);

if isTraining
    NUM_ITERATIONS = 5000; %change this value to set max iterations
    iterationCount(NUM_ITERATIONS) = 0;
else
    NUM_ITERATIONS = 10;
    if toLandmarks
        load('land_agent1_policy_weights.mat','-mat');
        load('land_agent2_policy_weights.mat','-mat');
        load('land_value_weights.mat','-mat'); 
    else
        load('station_agent1_policy_weights.mat','-mat');
        load('station_agent2_policy_weights.mat','-mat');
        load('station_value_weights.mat','-mat'); 
    end
    
    a1_p_estimator.set_weights(a1_p_weights);
    a2_p_estimator.set_weights(a2_p_weights);
    v_estimator.set_weights(v_weights);
end

rwd(NUM_ITERATIONS) = 0;
for itr=1:NUM_ITERATIONS 
    env.reset([0 0; 0 0]); 
    if ~isTraining
        randStart = rand(); % randmonly place two Spheros
        if randStart > 0.5
            startLocation = env.locA;
        else
            startLocation = circshift(env.locA, [1, 0]);
        end
        env.reset(startLocation); 
        env.render();%display the moving environment
    end
	state = env.current_location;    
    countActions = 0;%count how many actions in one iteration  
    done = false;
    
    while ~done   
        if countActions == maxItr
            break;
        end
        countActions = countActions + 1; 
        
        if ~isTraining
            prob_a1 = a1_p_estimator.predict(state,env.actionSpace);
            prob_a2 = a2_p_estimator.predict(state,env.actionSpace);
            action = [randsample(env.actionSpace,1,true,prob_a1) ...
                      randsample(env.actionSpace,1,true,prob_a2)]; 
            [next_state, reward, done] = env.step(action); % [action(1) 0]
            rwd(itr) = rwd(itr) + reward;
            state = next_state;
            env.render();%display the moving environment
            continue;
        end
        
        prob_a1 = a1_p_estimator.predict(state,env.actionSpace);
        prob_a2 = a2_p_estimator.predict(state,env.actionSpace);
        action = [randsample(env.actionSpace,1,true,prob_a1) ...
                  randsample(env.actionSpace,1,true,prob_a2)];  

        [next_state, reward, done] = env.step(action);
        
        if done
            td_err = reward - v_estimator.predict(state);
        else
            td_err = reward + gamma*v_estimator.predict(next_state) - v_estimator.predict(state);
        end
        v_estimator.update(state,td_err);
        a1_p_estimator.update(state,action(1),td_err);
        a2_p_estimator.update(state,action(2),td_err);
        rwd(itr) = rwd(itr) + reward;
        state = next_state;
    end
    fprintf('final location: %d, %d; %d, %d\n',state');
    fprintf('%d th iteration, %d actions taken, final reward is %d, accumulated reward is %d.\n',itr,countActions,reward,rwd(itr));
    if isTraining
        iterationCount(itr) = countActions;
    end
end
if isTraining
    a1_p_weights = a1_p_estimator.weights;
    a2_p_weights = a2_p_estimator.weights;
    v_weights = v_estimator.weights;
    if toLandmarks
        save('land_agent1_policy_weights.mat','a1_p_weights');
        save('land_agent2_policy_weights.mat','a2_p_weights');
        save('land_value_weights.mat','v_weights');
        save('land_iterationCount.mat','iterationCount');
        save('land_reward.mat','rwd');
    else
        save('station_agent1_policy_weights.mat','a1_p_weights');
        save('station_agent2_policy_weights.mat','a2_p_weights');
        save('station_value_weights.mat','v_weights');
        save('station_iterationCount.mat','iterationCount');
        save('station_reward.mat','rwd');
    end
end