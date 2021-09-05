import { r as react } from './common/index-ae389540.js';

var HandlerRole;

(function (HandlerRole) {
  HandlerRole["SOURCE"] = "SOURCE";
  HandlerRole["TARGET"] = "TARGET";
})(HandlerRole || (HandlerRole = {}));

function symbolObservablePonyfill(root) {
	var result;
	var Symbol = root.Symbol;

	if (typeof Symbol === 'function') {
		if (Symbol.observable) {
			result = Symbol.observable;
		} else {
			result = Symbol('observable');
			Symbol.observable = result;
		}
	} else {
		result = '@@observable';
	}

	return result;
}

/* global window */

var root;

if (typeof self !== 'undefined') {
  root = self;
} else if (typeof window !== 'undefined') {
  root = window;
} else if (typeof global !== 'undefined') {
  root = global;
} else if (typeof module !== 'undefined') {
  root = module;
} else {
  root = Function('return this')();
}

var result = symbolObservablePonyfill(root);

/**
 * These are private action types reserved by Redux.
 * For any unknown actions, you must return the current state.
 * If the current state is undefined, you must return the initial state.
 * Do not reference these action types directly in your code.
 */
var randomString = function randomString() {
  return Math.random().toString(36).substring(7).split('').join('.');
};

var ActionTypes = {
  INIT: "@@redux/INIT" + randomString(),
  REPLACE: "@@redux/REPLACE" + randomString(),
  PROBE_UNKNOWN_ACTION: function PROBE_UNKNOWN_ACTION() {
    return "@@redux/PROBE_UNKNOWN_ACTION" + randomString();
  }
};

/**
 * @param {any} obj The object to inspect.
 * @returns {boolean} True if the argument appears to be a plain object.
 */
function isPlainObject(obj) {
  if (typeof obj !== 'object' || obj === null) return false;
  var proto = obj;

  while (Object.getPrototypeOf(proto) !== null) {
    proto = Object.getPrototypeOf(proto);
  }

  return Object.getPrototypeOf(obj) === proto;
}

/**
 * Creates a Redux store that holds the state tree.
 * The only way to change the data in the store is to call `dispatch()` on it.
 *
 * There should only be a single store in your app. To specify how different
 * parts of the state tree respond to actions, you may combine several reducers
 * into a single reducer function by using `combineReducers`.
 *
 * @param {Function} reducer A function that returns the next state tree, given
 * the current state tree and the action to handle.
 *
 * @param {any} [preloadedState] The initial state. You may optionally specify it
 * to hydrate the state from the server in universal apps, or to restore a
 * previously serialized user session.
 * If you use `combineReducers` to produce the root reducer function, this must be
 * an object with the same shape as `combineReducers` keys.
 *
 * @param {Function} [enhancer] The store enhancer. You may optionally specify it
 * to enhance the store with third-party capabilities such as middleware,
 * time travel, persistence, etc. The only store enhancer that ships with Redux
 * is `applyMiddleware()`.
 *
 * @returns {Store} A Redux store that lets you read the state, dispatch actions
 * and subscribe to changes.
 */

function createStore(reducer, preloadedState, enhancer) {
  var _ref2;

  if (typeof preloadedState === 'function' && typeof enhancer === 'function' || typeof enhancer === 'function' && typeof arguments[3] === 'function') {
    throw new Error('It looks like you are passing several store enhancers to ' + 'createStore(). This is not supported. Instead, compose them ' + 'together to a single function.');
  }

  if (typeof preloadedState === 'function' && typeof enhancer === 'undefined') {
    enhancer = preloadedState;
    preloadedState = undefined;
  }

  if (typeof enhancer !== 'undefined') {
    if (typeof enhancer !== 'function') {
      throw new Error('Expected the enhancer to be a function.');
    }

    return enhancer(createStore)(reducer, preloadedState);
  }

  if (typeof reducer !== 'function') {
    throw new Error('Expected the reducer to be a function.');
  }

  var currentReducer = reducer;
  var currentState = preloadedState;
  var currentListeners = [];
  var nextListeners = currentListeners;
  var isDispatching = false;
  /**
   * This makes a shallow copy of currentListeners so we can use
   * nextListeners as a temporary list while dispatching.
   *
   * This prevents any bugs around consumers calling
   * subscribe/unsubscribe in the middle of a dispatch.
   */

  function ensureCanMutateNextListeners() {
    if (nextListeners === currentListeners) {
      nextListeners = currentListeners.slice();
    }
  }
  /**
   * Reads the state tree managed by the store.
   *
   * @returns {any} The current state tree of your application.
   */


  function getState() {
    if (isDispatching) {
      throw new Error('You may not call store.getState() while the reducer is executing. ' + 'The reducer has already received the state as an argument. ' + 'Pass it down from the top reducer instead of reading it from the store.');
    }

    return currentState;
  }
  /**
   * Adds a change listener. It will be called any time an action is dispatched,
   * and some part of the state tree may potentially have changed. You may then
   * call `getState()` to read the current state tree inside the callback.
   *
   * You may call `dispatch()` from a change listener, with the following
   * caveats:
   *
   * 1. The subscriptions are snapshotted just before every `dispatch()` call.
   * If you subscribe or unsubscribe while the listeners are being invoked, this
   * will not have any effect on the `dispatch()` that is currently in progress.
   * However, the next `dispatch()` call, whether nested or not, will use a more
   * recent snapshot of the subscription list.
   *
   * 2. The listener should not expect to see all state changes, as the state
   * might have been updated multiple times during a nested `dispatch()` before
   * the listener is called. It is, however, guaranteed that all subscribers
   * registered before the `dispatch()` started will be called with the latest
   * state by the time it exits.
   *
   * @param {Function} listener A callback to be invoked on every dispatch.
   * @returns {Function} A function to remove this change listener.
   */


  function subscribe(listener) {
    if (typeof listener !== 'function') {
      throw new Error('Expected the listener to be a function.');
    }

    if (isDispatching) {
      throw new Error('You may not call store.subscribe() while the reducer is executing. ' + 'If you would like to be notified after the store has been updated, subscribe from a ' + 'component and invoke store.getState() in the callback to access the latest state. ' + 'See https://redux.js.org/api-reference/store#subscribelistener for more details.');
    }

    var isSubscribed = true;
    ensureCanMutateNextListeners();
    nextListeners.push(listener);
    return function unsubscribe() {
      if (!isSubscribed) {
        return;
      }

      if (isDispatching) {
        throw new Error('You may not unsubscribe from a store listener while the reducer is executing. ' + 'See https://redux.js.org/api-reference/store#subscribelistener for more details.');
      }

      isSubscribed = false;
      ensureCanMutateNextListeners();
      var index = nextListeners.indexOf(listener);
      nextListeners.splice(index, 1);
      currentListeners = null;
    };
  }
  /**
   * Dispatches an action. It is the only way to trigger a state change.
   *
   * The `reducer` function, used to create the store, will be called with the
   * current state tree and the given `action`. Its return value will
   * be considered the **next** state of the tree, and the change listeners
   * will be notified.
   *
   * The base implementation only supports plain object actions. If you want to
   * dispatch a Promise, an Observable, a thunk, or something else, you need to
   * wrap your store creating function into the corresponding middleware. For
   * example, see the documentation for the `redux-thunk` package. Even the
   * middleware will eventually dispatch plain object actions using this method.
   *
   * @param {Object} action A plain object representing “what changed”. It is
   * a good idea to keep actions serializable so you can record and replay user
   * sessions, or use the time travelling `redux-devtools`. An action must have
   * a `type` property which may not be `undefined`. It is a good idea to use
   * string constants for action types.
   *
   * @returns {Object} For convenience, the same action object you dispatched.
   *
   * Note that, if you use a custom middleware, it may wrap `dispatch()` to
   * return something else (for example, a Promise you can await).
   */


  function dispatch(action) {
    if (!isPlainObject(action)) {
      throw new Error('Actions must be plain objects. ' + 'Use custom middleware for async actions.');
    }

    if (typeof action.type === 'undefined') {
      throw new Error('Actions may not have an undefined "type" property. ' + 'Have you misspelled a constant?');
    }

    if (isDispatching) {
      throw new Error('Reducers may not dispatch actions.');
    }

    try {
      isDispatching = true;
      currentState = currentReducer(currentState, action);
    } finally {
      isDispatching = false;
    }

    var listeners = currentListeners = nextListeners;

    for (var i = 0; i < listeners.length; i++) {
      var listener = listeners[i];
      listener();
    }

    return action;
  }
  /**
   * Replaces the reducer currently used by the store to calculate the state.
   *
   * You might need this if your app implements code splitting and you want to
   * load some of the reducers dynamically. You might also need this if you
   * implement a hot reloading mechanism for Redux.
   *
   * @param {Function} nextReducer The reducer for the store to use instead.
   * @returns {void}
   */


  function replaceReducer(nextReducer) {
    if (typeof nextReducer !== 'function') {
      throw new Error('Expected the nextReducer to be a function.');
    }

    currentReducer = nextReducer; // This action has a similiar effect to ActionTypes.INIT.
    // Any reducers that existed in both the new and old rootReducer
    // will receive the previous state. This effectively populates
    // the new state tree with any relevant data from the old one.

    dispatch({
      type: ActionTypes.REPLACE
    });
  }
  /**
   * Interoperability point for observable/reactive libraries.
   * @returns {observable} A minimal observable of state changes.
   * For more information, see the observable proposal:
   * https://github.com/tc39/proposal-observable
   */


  function observable() {
    var _ref;

    var outerSubscribe = subscribe;
    return _ref = {
      /**
       * The minimal observable subscription method.
       * @param {Object} observer Any object that can be used as an observer.
       * The observer object should have a `next` method.
       * @returns {subscription} An object with an `unsubscribe` method that can
       * be used to unsubscribe the observable from the store, and prevent further
       * emission of values from the observable.
       */
      subscribe: function subscribe(observer) {
        if (typeof observer !== 'object' || observer === null) {
          throw new TypeError('Expected the observer to be an object.');
        }

        function observeState() {
          if (observer.next) {
            observer.next(getState());
          }
        }

        observeState();
        var unsubscribe = outerSubscribe(observeState);
        return {
          unsubscribe: unsubscribe
        };
      }
    }, _ref[result] = function () {
      return this;
    }, _ref;
  } // When a store is created, an "INIT" action is dispatched so that every
  // reducer returns their initial state. This effectively populates
  // the initial state tree.


  dispatch({
    type: ActionTypes.INIT
  });
  return _ref2 = {
    dispatch: dispatch,
    subscribe: subscribe,
    getState: getState,
    replaceReducer: replaceReducer
  }, _ref2[result] = observable, _ref2;
}

/**
 * Use invariant() to assert state which your program assumes to be true.
 *
 * Provide sprintf-style format (only %s is supported) and arguments
 * to provide information about what broke and what you were
 * expecting.
 *
 * The invariant message will be stripped in production, but the invariant
 * will remain to ensure logic does not differ in production.
 */
function invariant(condition, format) {
  for (var _len = arguments.length, args = new Array(_len > 2 ? _len - 2 : 0), _key = 2; _key < _len; _key++) {
    args[_key - 2] = arguments[_key];
  }

  if (!condition) {
    var error;

    if (format === undefined) {
      error = new Error('Minified exception occurred; use the non-minified dev environment ' + 'for the full error message and additional helpful warnings.');
    } else {
      var argIndex = 0;
      error = new Error(format.replace(/%s/g, function () {
        return args[argIndex++];
      }));
      error.name = 'Invariant Violation';
    }

    error.framesToPop = 1; // we don't care about invariant's own frame

    throw error;
  }
}

var INIT_COORDS = 'dnd-core/INIT_COORDS';
var BEGIN_DRAG = 'dnd-core/BEGIN_DRAG';
var PUBLISH_DRAG_SOURCE = 'dnd-core/PUBLISH_DRAG_SOURCE';
var HOVER = 'dnd-core/HOVER';
var DROP = 'dnd-core/DROP';
var END_DRAG = 'dnd-core/END_DRAG';

function setClientOffset(clientOffset, sourceClientOffset) {
  return {
    type: INIT_COORDS,
    payload: {
      sourceClientOffset: sourceClientOffset || null,
      clientOffset: clientOffset || null
    }
  };
}

function _typeof$3(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof$3 = function _typeof(obj) { return typeof obj; }; } else { _typeof$3 = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof$3(obj); }

// cheap lodash replacements

/**
 * drop-in replacement for _.get
 * @param obj
 * @param path
 * @param defaultValue
 */
function get(obj, path, defaultValue) {
  return path.split('.').reduce(function (a, c) {
    return a && a[c] ? a[c] : defaultValue || null;
  }, obj);
}
/**
 * drop-in replacement for _.without
 */

function without(items, item) {
  return items.filter(function (i) {
    return i !== item;
  });
}
/**
 * drop-in replacement for _.isString
 * @param input
 */

function isObject(input) {
  return _typeof$3(input) === 'object';
}
/**
 * repalcement for _.xor
 * @param itemsA
 * @param itemsB
 */

function xor(itemsA, itemsB) {
  var map = new Map();

  var insertItem = function insertItem(item) {
    map.set(item, map.has(item) ? map.get(item) + 1 : 1);
  };

  itemsA.forEach(insertItem);
  itemsB.forEach(insertItem);
  var result = [];
  map.forEach(function (count, key) {
    if (count === 1) {
      result.push(key);
    }
  });
  return result;
}
/**
 * replacement for _.intersection
 * @param itemsA
 * @param itemsB
 */

function intersection(itemsA, itemsB) {
  return itemsA.filter(function (t) {
    return itemsB.indexOf(t) > -1;
  });
}

var ResetCoordinatesAction = {
  type: INIT_COORDS,
  payload: {
    clientOffset: null,
    sourceClientOffset: null
  }
};
function createBeginDrag(manager) {
  return function beginDrag() {
    var sourceIds = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : [];
    var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {
      publishSource: true
    };
    var _options$publishSourc = options.publishSource,
        publishSource = _options$publishSourc === void 0 ? true : _options$publishSourc,
        clientOffset = options.clientOffset,
        getSourceClientOffset = options.getSourceClientOffset;
    var monitor = manager.getMonitor();
    var registry = manager.getRegistry(); // Initialize the coordinates using the client offset

    manager.dispatch(setClientOffset(clientOffset));
    verifyInvariants$1(sourceIds, monitor, registry); // Get the draggable source

    var sourceId = getDraggableSource(sourceIds, monitor);

    if (sourceId === null) {
      manager.dispatch(ResetCoordinatesAction);
      return;
    } // Get the source client offset


    var sourceClientOffset = null;

    if (clientOffset) {
      if (!getSourceClientOffset) {
        throw new Error('getSourceClientOffset must be defined');
      }

      verifyGetSourceClientOffsetIsFunction(getSourceClientOffset);
      sourceClientOffset = getSourceClientOffset(sourceId);
    } // Initialize the full coordinates


    manager.dispatch(setClientOffset(clientOffset, sourceClientOffset));
    var source = registry.getSource(sourceId);
    var item = source.beginDrag(monitor, sourceId);
    verifyItemIsObject(item);
    registry.pinSource(sourceId);
    var itemType = registry.getSourceType(sourceId);
    return {
      type: BEGIN_DRAG,
      payload: {
        itemType: itemType,
        item: item,
        sourceId: sourceId,
        clientOffset: clientOffset || null,
        sourceClientOffset: sourceClientOffset || null,
        isSourcePublic: !!publishSource
      }
    };
  };
}

function verifyInvariants$1(sourceIds, monitor, registry) {
  invariant(!monitor.isDragging(), 'Cannot call beginDrag while dragging.');
  sourceIds.forEach(function (sourceId) {
    invariant(registry.getSource(sourceId), 'Expected sourceIds to be registered.');
  });
}

function verifyGetSourceClientOffsetIsFunction(getSourceClientOffset) {
  invariant(typeof getSourceClientOffset === 'function', 'When clientOffset is provided, getSourceClientOffset must be a function.');
}

function verifyItemIsObject(item) {
  invariant(isObject(item), 'Item must be an object.');
}

function getDraggableSource(sourceIds, monitor) {
  var sourceId = null;

  for (var i = sourceIds.length - 1; i >= 0; i--) {
    if (monitor.canDragSource(sourceIds[i])) {
      sourceId = sourceIds[i];
      break;
    }
  }

  return sourceId;
}

function createPublishDragSource(manager) {
  return function publishDragSource() {
    var monitor = manager.getMonitor();

    if (monitor.isDragging()) {
      return {
        type: PUBLISH_DRAG_SOURCE
      };
    }
  };
}

function matchesType(targetType, draggedItemType) {
  if (draggedItemType === null) {
    return targetType === null;
  }

  return Array.isArray(targetType) ? targetType.some(function (t) {
    return t === draggedItemType;
  }) : targetType === draggedItemType;
}

function createHover(manager) {
  return function hover(targetIdsArg) {
    var _ref = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {},
        clientOffset = _ref.clientOffset;

    verifyTargetIdsIsArray(targetIdsArg);
    var targetIds = targetIdsArg.slice(0);
    var monitor = manager.getMonitor();
    var registry = manager.getRegistry();
    checkInvariants(targetIds, monitor, registry);
    var draggedItemType = monitor.getItemType();
    removeNonMatchingTargetIds(targetIds, registry, draggedItemType);
    hoverAllTargets(targetIds, monitor, registry);
    return {
      type: HOVER,
      payload: {
        targetIds: targetIds,
        clientOffset: clientOffset || null
      }
    };
  };
}

function verifyTargetIdsIsArray(targetIdsArg) {
  invariant(Array.isArray(targetIdsArg), 'Expected targetIds to be an array.');
}

function checkInvariants(targetIds, monitor, registry) {
  invariant(monitor.isDragging(), 'Cannot call hover while not dragging.');
  invariant(!monitor.didDrop(), 'Cannot call hover after drop.');

  for (var i = 0; i < targetIds.length; i++) {
    var targetId = targetIds[i];
    invariant(targetIds.lastIndexOf(targetId) === i, 'Expected targetIds to be unique in the passed array.');
    var target = registry.getTarget(targetId);
    invariant(target, 'Expected targetIds to be registered.');
  }
}

function removeNonMatchingTargetIds(targetIds, registry, draggedItemType) {
  // Remove those targetIds that don't match the targetType.  This
  // fixes shallow isOver which would only be non-shallow because of
  // non-matching targets.
  for (var i = targetIds.length - 1; i >= 0; i--) {
    var targetId = targetIds[i];
    var targetType = registry.getTargetType(targetId);

    if (!matchesType(targetType, draggedItemType)) {
      targetIds.splice(i, 1);
    }
  }
}

function hoverAllTargets(targetIds, monitor, registry) {
  // Finally call hover on all matching targets.
  targetIds.forEach(function (targetId) {
    var target = registry.getTarget(targetId);
    target.hover(monitor, targetId);
  });
}

function ownKeys$3(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); if (enumerableOnly) symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; }); keys.push.apply(keys, symbols); } return keys; }

function _objectSpread$3(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; if (i % 2) { ownKeys$3(Object(source), true).forEach(function (key) { _defineProperty$3(target, key, source[key]); }); } else if (Object.getOwnPropertyDescriptors) { Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)); } else { ownKeys$3(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } } return target; }

function _defineProperty$3(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
function createDrop(manager) {
  return function drop() {
    var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
    var monitor = manager.getMonitor();
    var registry = manager.getRegistry();
    verifyInvariants(monitor);
    var targetIds = getDroppableTargets(monitor); // Multiple actions are dispatched here, which is why this doesn't return an action

    targetIds.forEach(function (targetId, index) {
      var dropResult = determineDropResult(targetId, index, registry, monitor);
      var action = {
        type: DROP,
        payload: {
          dropResult: _objectSpread$3(_objectSpread$3({}, options), dropResult)
        }
      };
      manager.dispatch(action);
    });
  };
}

function verifyInvariants(monitor) {
  invariant(monitor.isDragging(), 'Cannot call drop while not dragging.');
  invariant(!monitor.didDrop(), 'Cannot call drop twice during one drag operation.');
}

function determineDropResult(targetId, index, registry, monitor) {
  var target = registry.getTarget(targetId);
  var dropResult = target ? target.drop(monitor, targetId) : undefined;
  verifyDropResultType(dropResult);

  if (typeof dropResult === 'undefined') {
    dropResult = index === 0 ? {} : monitor.getDropResult();
  }

  return dropResult;
}

function verifyDropResultType(dropResult) {
  invariant(typeof dropResult === 'undefined' || isObject(dropResult), 'Drop result must either be an object or undefined.');
}

function getDroppableTargets(monitor) {
  var targetIds = monitor.getTargetIds().filter(monitor.canDropOnTarget, monitor);
  targetIds.reverse();
  return targetIds;
}

function createEndDrag(manager) {
  return function endDrag() {
    var monitor = manager.getMonitor();
    var registry = manager.getRegistry();
    verifyIsDragging(monitor);
    var sourceId = monitor.getSourceId();

    if (sourceId != null) {
      var source = registry.getSource(sourceId, true);
      source.endDrag(monitor, sourceId);
      registry.unpinSource();
    }

    return {
      type: END_DRAG
    };
  };
}

function verifyIsDragging(monitor) {
  invariant(monitor.isDragging(), 'Cannot call endDrag while not dragging.');
}

function createDragDropActions(manager) {
  return {
    beginDrag: createBeginDrag(manager),
    publishDragSource: createPublishDragSource(manager),
    hover: createHover(manager),
    drop: createDrop(manager),
    endDrag: createEndDrag(manager)
  };
}

var strictEquality = function strictEquality(a, b) {
  return a === b;
};
/**
 * Determine if two cartesian coordinate offsets are equal
 * @param offsetA
 * @param offsetB
 */

function areCoordsEqual(offsetA, offsetB) {
  if (!offsetA && !offsetB) {
    return true;
  } else if (!offsetA || !offsetB) {
    return false;
  } else {
    return offsetA.x === offsetB.x && offsetA.y === offsetB.y;
  }
}
/**
 * Determines if two arrays of items are equal
 * @param a The first array of items
 * @param b The second array of items
 */

function areArraysEqual(a, b) {
  var isEqual = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : strictEquality;

  if (a.length !== b.length) {
    return false;
  }

  for (var i = 0; i < a.length; ++i) {
    if (!isEqual(a[i], b[i])) {
      return false;
    }
  }

  return true;
}

function ownKeys$2(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); if (enumerableOnly) symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; }); keys.push.apply(keys, symbols); } return keys; }

function _objectSpread$2(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; if (i % 2) { ownKeys$2(Object(source), true).forEach(function (key) { _defineProperty$2(target, key, source[key]); }); } else if (Object.getOwnPropertyDescriptors) { Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)); } else { ownKeys$2(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } } return target; }

function _defineProperty$2(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
var initialState$1 = {
  initialSourceClientOffset: null,
  initialClientOffset: null,
  clientOffset: null
};
function reduce$5() {
  var state = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : initialState$1;
  var action = arguments.length > 1 ? arguments[1] : undefined;
  var payload = action.payload;

  switch (action.type) {
    case INIT_COORDS:
    case BEGIN_DRAG:
      return {
        initialSourceClientOffset: payload.sourceClientOffset,
        initialClientOffset: payload.clientOffset,
        clientOffset: payload.clientOffset
      };

    case HOVER:
      if (areCoordsEqual(state.clientOffset, payload.clientOffset)) {
        return state;
      }

      return _objectSpread$2(_objectSpread$2({}, state), {}, {
        clientOffset: payload.clientOffset
      });

    case END_DRAG:
    case DROP:
      return initialState$1;

    default:
      return state;
  }
}

var ADD_SOURCE = 'dnd-core/ADD_SOURCE';
var ADD_TARGET = 'dnd-core/ADD_TARGET';
var REMOVE_SOURCE = 'dnd-core/REMOVE_SOURCE';
var REMOVE_TARGET = 'dnd-core/REMOVE_TARGET';
function addSource(sourceId) {
  return {
    type: ADD_SOURCE,
    payload: {
      sourceId: sourceId
    }
  };
}
function addTarget(targetId) {
  return {
    type: ADD_TARGET,
    payload: {
      targetId: targetId
    }
  };
}
function removeSource(sourceId) {
  return {
    type: REMOVE_SOURCE,
    payload: {
      sourceId: sourceId
    }
  };
}
function removeTarget(targetId) {
  return {
    type: REMOVE_TARGET,
    payload: {
      targetId: targetId
    }
  };
}

function ownKeys$1(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); if (enumerableOnly) symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; }); keys.push.apply(keys, symbols); } return keys; }

function _objectSpread$1(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; if (i % 2) { ownKeys$1(Object(source), true).forEach(function (key) { _defineProperty$1(target, key, source[key]); }); } else if (Object.getOwnPropertyDescriptors) { Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)); } else { ownKeys$1(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } } return target; }

function _defineProperty$1(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
var initialState = {
  itemType: null,
  item: null,
  sourceId: null,
  targetIds: [],
  dropResult: null,
  didDrop: false,
  isSourcePublic: null
};
function reduce$4() {
  var state = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : initialState;
  var action = arguments.length > 1 ? arguments[1] : undefined;
  var payload = action.payload;

  switch (action.type) {
    case BEGIN_DRAG:
      return _objectSpread$1(_objectSpread$1({}, state), {}, {
        itemType: payload.itemType,
        item: payload.item,
        sourceId: payload.sourceId,
        isSourcePublic: payload.isSourcePublic,
        dropResult: null,
        didDrop: false
      });

    case PUBLISH_DRAG_SOURCE:
      return _objectSpread$1(_objectSpread$1({}, state), {}, {
        isSourcePublic: true
      });

    case HOVER:
      return _objectSpread$1(_objectSpread$1({}, state), {}, {
        targetIds: payload.targetIds
      });

    case REMOVE_TARGET:
      if (state.targetIds.indexOf(payload.targetId) === -1) {
        return state;
      }

      return _objectSpread$1(_objectSpread$1({}, state), {}, {
        targetIds: without(state.targetIds, payload.targetId)
      });

    case DROP:
      return _objectSpread$1(_objectSpread$1({}, state), {}, {
        dropResult: payload.dropResult,
        didDrop: true,
        targetIds: []
      });

    case END_DRAG:
      return _objectSpread$1(_objectSpread$1({}, state), {}, {
        itemType: null,
        item: null,
        sourceId: null,
        dropResult: null,
        didDrop: false,
        isSourcePublic: null,
        targetIds: []
      });

    default:
      return state;
  }
}

function reduce$3() {
  var state = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 0;
  var action = arguments.length > 1 ? arguments[1] : undefined;

  switch (action.type) {
    case ADD_SOURCE:
    case ADD_TARGET:
      return state + 1;

    case REMOVE_SOURCE:
    case REMOVE_TARGET:
      return state - 1;

    default:
      return state;
  }
}

var NONE = [];
var ALL = [];
NONE.__IS_NONE__ = true;
ALL.__IS_ALL__ = true;
/**
 * Determines if the given handler IDs are dirty or not.
 *
 * @param dirtyIds The set of dirty handler ids
 * @param handlerIds The set of handler ids to check
 */

function areDirty(dirtyIds, handlerIds) {
  if (dirtyIds === NONE) {
    return false;
  }

  if (dirtyIds === ALL || typeof handlerIds === 'undefined') {
    return true;
  }

  var commonIds = intersection(handlerIds, dirtyIds);
  return commonIds.length > 0;
}

function reduce$2() {

  var action = arguments.length > 1 ? arguments[1] : undefined;

  switch (action.type) {
    case HOVER:
      break;

    case ADD_SOURCE:
    case ADD_TARGET:
    case REMOVE_TARGET:
    case REMOVE_SOURCE:
      return NONE;

    case BEGIN_DRAG:
    case PUBLISH_DRAG_SOURCE:
    case END_DRAG:
    case DROP:
    default:
      return ALL;
  }

  var _action$payload = action.payload,
      _action$payload$targe = _action$payload.targetIds,
      targetIds = _action$payload$targe === void 0 ? [] : _action$payload$targe,
      _action$payload$prevT = _action$payload.prevTargetIds,
      prevTargetIds = _action$payload$prevT === void 0 ? [] : _action$payload$prevT;
  var result = xor(targetIds, prevTargetIds);
  var didChange = result.length > 0 || !areArraysEqual(targetIds, prevTargetIds);

  if (!didChange) {
    return NONE;
  } // Check the target ids at the innermost position. If they are valid, add them
  // to the result


  var prevInnermostTargetId = prevTargetIds[prevTargetIds.length - 1];
  var innermostTargetId = targetIds[targetIds.length - 1];

  if (prevInnermostTargetId !== innermostTargetId) {
    if (prevInnermostTargetId) {
      result.push(prevInnermostTargetId);
    }

    if (innermostTargetId) {
      result.push(innermostTargetId);
    }
  }

  return result;
}

function reduce$1() {
  var state = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 0;
  return state + 1;
}

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); if (enumerableOnly) symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; }); keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; if (i % 2) { ownKeys(Object(source), true).forEach(function (key) { _defineProperty(target, key, source[key]); }); } else if (Object.getOwnPropertyDescriptors) { Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)); } else { ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
function reduce() {
  var state = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
  var action = arguments.length > 1 ? arguments[1] : undefined;
  return {
    dirtyHandlerIds: reduce$2(state.dirtyHandlerIds, {
      type: action.type,
      payload: _objectSpread(_objectSpread({}, action.payload), {}, {
        prevTargetIds: get(state, 'dragOperation.targetIds', [])
      })
    }),
    dragOffset: reduce$5(state.dragOffset, action),
    refCount: reduce$3(state.refCount, action),
    dragOperation: reduce$4(state.dragOperation, action),
    stateId: reduce$1(state.stateId)
  };
}

/**
 * Coordinate addition
 * @param a The first coordinate
 * @param b The second coordinate
 */
function add(a, b) {
  return {
    x: a.x + b.x,
    y: a.y + b.y
  };
}
/**
 * Coordinate subtraction
 * @param a The first coordinate
 * @param b The second coordinate
 */

function subtract(a, b) {
  return {
    x: a.x - b.x,
    y: a.y - b.y
  };
}
/**
 * Returns the cartesian distance of the drag source component's position, based on its position
 * at the time when the current drag operation has started, and the movement difference.
 *
 * Returns null if no item is being dragged.
 *
 * @param state The offset state to compute from
 */

function getSourceClientOffset(state) {
  var clientOffset = state.clientOffset,
      initialClientOffset = state.initialClientOffset,
      initialSourceClientOffset = state.initialSourceClientOffset;

  if (!clientOffset || !initialClientOffset || !initialSourceClientOffset) {
    return null;
  }

  return subtract(add(clientOffset, initialSourceClientOffset), initialClientOffset);
}
/**
 * Determines the x,y offset between the client offset and the initial client offset
 *
 * @param state The offset state to compute from
 */

function getDifferenceFromInitialOffset(state) {
  var clientOffset = state.clientOffset,
      initialClientOffset = state.initialClientOffset;

  if (!clientOffset || !initialClientOffset) {
    return null;
  }

  return subtract(clientOffset, initialClientOffset);
}

function _classCallCheck$6(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties$6(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass$6(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties$6(Constructor.prototype, protoProps); if (staticProps) _defineProperties$6(Constructor, staticProps); return Constructor; }
var DragDropMonitorImpl = /*#__PURE__*/function () {
  function DragDropMonitorImpl(store, registry) {
    _classCallCheck$6(this, DragDropMonitorImpl);

    this.store = store;
    this.registry = registry;
  }

  _createClass$6(DragDropMonitorImpl, [{
    key: "subscribeToStateChange",
    value: function subscribeToStateChange(listener) {
      var _this = this;

      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {
        handlerIds: undefined
      };
      var handlerIds = options.handlerIds;
      invariant(typeof listener === 'function', 'listener must be a function.');
      invariant(typeof handlerIds === 'undefined' || Array.isArray(handlerIds), 'handlerIds, when specified, must be an array of strings.');
      var prevStateId = this.store.getState().stateId;

      var handleChange = function handleChange() {
        var state = _this.store.getState();

        var currentStateId = state.stateId;

        try {
          var canSkipListener = currentStateId === prevStateId || currentStateId === prevStateId + 1 && !areDirty(state.dirtyHandlerIds, handlerIds);

          if (!canSkipListener) {
            listener();
          }
        } finally {
          prevStateId = currentStateId;
        }
      };

      return this.store.subscribe(handleChange);
    }
  }, {
    key: "subscribeToOffsetChange",
    value: function subscribeToOffsetChange(listener) {
      var _this2 = this;

      invariant(typeof listener === 'function', 'listener must be a function.');
      var previousState = this.store.getState().dragOffset;

      var handleChange = function handleChange() {
        var nextState = _this2.store.getState().dragOffset;

        if (nextState === previousState) {
          return;
        }

        previousState = nextState;
        listener();
      };

      return this.store.subscribe(handleChange);
    }
  }, {
    key: "canDragSource",
    value: function canDragSource(sourceId) {
      if (!sourceId) {
        return false;
      }

      var source = this.registry.getSource(sourceId);
      invariant(source, 'Expected to find a valid source.');

      if (this.isDragging()) {
        return false;
      }

      return source.canDrag(this, sourceId);
    }
  }, {
    key: "canDropOnTarget",
    value: function canDropOnTarget(targetId) {
      // undefined on initial render
      if (!targetId) {
        return false;
      }

      var target = this.registry.getTarget(targetId);
      invariant(target, 'Expected to find a valid target.');

      if (!this.isDragging() || this.didDrop()) {
        return false;
      }

      var targetType = this.registry.getTargetType(targetId);
      var draggedItemType = this.getItemType();
      return matchesType(targetType, draggedItemType) && target.canDrop(this, targetId);
    }
  }, {
    key: "isDragging",
    value: function isDragging() {
      return Boolean(this.getItemType());
    }
  }, {
    key: "isDraggingSource",
    value: function isDraggingSource(sourceId) {
      // undefined on initial render
      if (!sourceId) {
        return false;
      }

      var source = this.registry.getSource(sourceId, true);
      invariant(source, 'Expected to find a valid source.');

      if (!this.isDragging() || !this.isSourcePublic()) {
        return false;
      }

      var sourceType = this.registry.getSourceType(sourceId);
      var draggedItemType = this.getItemType();

      if (sourceType !== draggedItemType) {
        return false;
      }

      return source.isDragging(this, sourceId);
    }
  }, {
    key: "isOverTarget",
    value: function isOverTarget(targetId) {
      var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {
        shallow: false
      };

      // undefined on initial render
      if (!targetId) {
        return false;
      }

      var shallow = options.shallow;

      if (!this.isDragging()) {
        return false;
      }

      var targetType = this.registry.getTargetType(targetId);
      var draggedItemType = this.getItemType();

      if (draggedItemType && !matchesType(targetType, draggedItemType)) {
        return false;
      }

      var targetIds = this.getTargetIds();

      if (!targetIds.length) {
        return false;
      }

      var index = targetIds.indexOf(targetId);

      if (shallow) {
        return index === targetIds.length - 1;
      } else {
        return index > -1;
      }
    }
  }, {
    key: "getItemType",
    value: function getItemType() {
      return this.store.getState().dragOperation.itemType;
    }
  }, {
    key: "getItem",
    value: function getItem() {
      return this.store.getState().dragOperation.item;
    }
  }, {
    key: "getSourceId",
    value: function getSourceId() {
      return this.store.getState().dragOperation.sourceId;
    }
  }, {
    key: "getTargetIds",
    value: function getTargetIds() {
      return this.store.getState().dragOperation.targetIds;
    }
  }, {
    key: "getDropResult",
    value: function getDropResult() {
      return this.store.getState().dragOperation.dropResult;
    }
  }, {
    key: "didDrop",
    value: function didDrop() {
      return this.store.getState().dragOperation.didDrop;
    }
  }, {
    key: "isSourcePublic",
    value: function isSourcePublic() {
      return Boolean(this.store.getState().dragOperation.isSourcePublic);
    }
  }, {
    key: "getInitialClientOffset",
    value: function getInitialClientOffset() {
      return this.store.getState().dragOffset.initialClientOffset;
    }
  }, {
    key: "getInitialSourceClientOffset",
    value: function getInitialSourceClientOffset() {
      return this.store.getState().dragOffset.initialSourceClientOffset;
    }
  }, {
    key: "getClientOffset",
    value: function getClientOffset() {
      return this.store.getState().dragOffset.clientOffset;
    }
  }, {
    key: "getSourceClientOffset",
    value: function getSourceClientOffset$1() {
      return getSourceClientOffset(this.store.getState().dragOffset);
    }
  }, {
    key: "getDifferenceFromInitialOffset",
    value: function getDifferenceFromInitialOffset$1() {
      return getDifferenceFromInitialOffset(this.store.getState().dragOffset);
    }
  }]);

  return DragDropMonitorImpl;
}();

var nextUniqueId = 0;
function getNextUniqueId() {
  return nextUniqueId++;
}

function _typeof$2(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof$2 = function _typeof(obj) { return typeof obj; }; } else { _typeof$2 = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof$2(obj); }
function validateSourceContract(source) {
  invariant(typeof source.canDrag === 'function', 'Expected canDrag to be a function.');
  invariant(typeof source.beginDrag === 'function', 'Expected beginDrag to be a function.');
  invariant(typeof source.endDrag === 'function', 'Expected endDrag to be a function.');
}
function validateTargetContract(target) {
  invariant(typeof target.canDrop === 'function', 'Expected canDrop to be a function.');
  invariant(typeof target.hover === 'function', 'Expected hover to be a function.');
  invariant(typeof target.drop === 'function', 'Expected beginDrag to be a function.');
}
function validateType(type, allowArray) {
  if (allowArray && Array.isArray(type)) {
    type.forEach(function (t) {
      return validateType(t, false);
    });
    return;
  }

  invariant(typeof type === 'string' || _typeof$2(type) === 'symbol', allowArray ? 'Type can only be a string, a symbol, or an array of either.' : 'Type can only be a string or a symbol.');
}

// Use the fastest means possible to execute a task in its own turn, with
// priority over other events including IO, animation, reflow, and redraw
// events in browsers.
//
// An exception thrown by a task will permanently interrupt the processing of
// subsequent tasks. The higher level `asap` function ensures that if an
// exception is thrown by a task, that the task queue will continue flushing as
// soon as possible, but if you use `rawAsap` directly, you are responsible to
// either ensure that no exceptions are thrown from your task, or to manually
// call `rawAsap.requestFlush` if an exception is thrown.
function rawAsap(task) {
  if (!queue.length) {
    requestFlush();
  } // Equivalent to push, but avoids a function call.


  queue[queue.length] = task;
}
var queue = []; // Once a flush has been requested, no further calls to `requestFlush` are
// off a `flush` event as quickly as possible. `flush` will attempt to exhaust
// the event queue before yielding to the browser's own event loop.

var requestFlush; // The position of the next task to execute in the task queue. This is
// preserved between calls to `flush` so that it can be resumed if
// a task throws an exception.

var index = 0; // If a task schedules additional tasks recursively, the task queue can grow
// unbounded. To prevent memory exhaustion, the task queue will periodically
// truncate already-completed tasks.

var capacity = 1024; // The flush function processes all tasks that have been scheduled with
// `rawAsap` unless and until one of those tasks throws an exception.
// If a task throws an exception, `flush` ensures that its state will remain
// consistent and will resume where it left off when called again.
// However, `flush` does not make any arrangements to be called again if an
// exception is thrown.

function flush() {
  while (index < queue.length) {
    var currentIndex = index; // Advance the index before calling the task. This ensures that we will
    // begin flushing on the next task the task throws an error.

    index = index + 1;
    queue[currentIndex].call(); // Prevent leaking memory for long chains of recursive calls to `asap`.
    // If we call `asap` within tasks scheduled by `asap`, the queue will
    // grow, but to avoid an O(n) walk for every task we execute, we don't
    // shift tasks off the queue after they have been executed.
    // Instead, we periodically shift 1024 tasks off the queue.

    if (index > capacity) {
      // Manually shift all values starting at the index back to the
      // beginning of the queue.
      for (var scan = 0, newLength = queue.length - index; scan < newLength; scan++) {
        queue[scan] = queue[scan + index];
      }

      queue.length -= index;
      index = 0;
    }
  }

  queue.length = 0;
  index = 0;
} // `requestFlush` is implemented using a strategy based on data collected from
// every available SauceLabs Selenium web driver worker at time of writing.
// https://docs.google.com/spreadsheets/d/1mG-5UYGup5qxGdEMWkhP6BWCz053NUb2E1QoUTU16uA/edit#gid=783724593
// Safari 6 and 6.1 for desktop, iPad, and iPhone are the only browsers that
// have WebKitMutationObserver but not un-prefixed MutationObserver.
// Must use `global` or `self` instead of `window` to work in both frames and web
// workers. `global` is a provision of Browserify, Mr, Mrs, or Mop.

/* globals self */


var scope = typeof global !== 'undefined' ? global : self;
var BrowserMutationObserver = scope.MutationObserver || scope.WebKitMutationObserver; // MutationObservers are desirable because they have high priority and work
// reliably everywhere they are implemented.
// They are implemented in all modern browsers.
//
// - Android 4-4.3
// - Chrome 26-34
// - Firefox 14-29
// - Internet Explorer 11
// - iPad Safari 6-7.1
// - iPhone Safari 7-7.1
// - Safari 6-7

if (typeof BrowserMutationObserver === 'function') {
  requestFlush = makeRequestCallFromMutationObserver(flush); // MessageChannels are desirable because they give direct access to the HTML
  // task queue, are implemented in Internet Explorer 10, Safari 5.0-1, and Opera
  // 11-12, and in web workers in many engines.
  // Although message channels yield to any queued rendering and IO tasks, they
  // would be better than imposing the 4ms delay of timers.
  // However, they do not work reliably in Internet Explorer or Safari.
  // Internet Explorer 10 is the only browser that has setImmediate but does
  // not have MutationObservers.
  // Although setImmediate yields to the browser's renderer, it would be
  // preferrable to falling back to setTimeout since it does not have
  // the minimum 4ms penalty.
  // Unfortunately there appears to be a bug in Internet Explorer 10 Mobile (and
  // Desktop to a lesser extent) that renders both setImmediate and
  // MessageChannel useless for the purposes of ASAP.
  // https://github.com/kriskowal/q/issues/396
  // Timers are implemented universally.
  // We fall back to timers in workers in most engines, and in foreground
  // contexts in the following browsers.
  // However, note that even this simple case requires nuances to operate in a
  // broad spectrum of browsers.
  //
  // - Firefox 3-13
  // - Internet Explorer 6-9
  // - iPad Safari 4.3
  // - Lynx 2.8.7
} else {
  requestFlush = makeRequestCallFromTimer(flush);
} // `requestFlush` requests that the high priority event queue be flushed as
// soon as possible.
// This is useful to prevent an error thrown in a task from stalling the event
// queue if the exception handled by Node.js’s
// `process.on("uncaughtException")` or by a domain.


rawAsap.requestFlush = requestFlush; // To request a high priority event, we induce a mutation observer by toggling
// the text of a text node between "1" and "-1".

function makeRequestCallFromMutationObserver(callback) {
  var toggle = 1;
  var observer = new BrowserMutationObserver(callback);
  var node = document.createTextNode('');
  observer.observe(node, {
    characterData: true
  });
  return function requestCall() {
    toggle = -toggle;
    node.data = toggle;
  };
} // The message channel technique was discovered by Malte Ubl and was the
// original foundation for this library.
// http://www.nonblocking.io/2011/06/windownexttick.html
// Safari 6.0.5 (at least) intermittently fails to create message ports on a
// page's first load. Thankfully, this version of Safari supports
// MutationObservers, so we don't need to fall back in that case.
// function makeRequestCallFromMessageChannel(callback) {
//     var channel = new MessageChannel();
//     channel.port1.onmessage = callback;
//     return function requestCall() {
//         channel.port2.postMessage(0);
//     };
// }
// For reasons explained above, we are also unable to use `setImmediate`
// under any circumstances.
// Even if we were, there is another bug in Internet Explorer 10.
// It is not sufficient to assign `setImmediate` to `requestFlush` because
// `setImmediate` must be called *by name* and therefore must be wrapped in a
// closure.
// Never forget.
// function makeRequestCallFromSetImmediate(callback) {
//     return function requestCall() {
//         setImmediate(callback);
//     };
// }
// Safari 6.0 has a problem where timers will get lost while the user is
// scrolling. This problem does not impact ASAP because Safari 6.0 supports
// mutation observers, so that implementation is used instead.
// However, if we ever elect to use timers in Safari, the prevalent work-around
// is to add a scroll event listener that calls for a flush.
// `setTimeout` does not call the passed callback if the delay is less than
// approximately 7 in web workers in Firefox 8 through 18, and sometimes not
// even then.


function makeRequestCallFromTimer(callback) {
  return function requestCall() {
    // We dispatch a timeout with a specified delay of 0 for engines that
    // can reliably accommodate that request. This will usually be snapped
    // to a 4 milisecond delay, but once we're flushing, there's no delay
    // between events.
    var timeoutHandle = setTimeout(handleTimer, 0); // However, since this timer gets frequently dropped in Firefox
    // workers, we enlist an interval handle that will try to fire
    // an event 20 times per second until it succeeds.

    var intervalHandle = setInterval(handleTimer, 50);

    function handleTimer() {
      // Whichever timer succeeds will cancel both timers and
      // execute the callback.
      clearTimeout(timeoutHandle);
      clearInterval(intervalHandle);
      callback();
    }
  };
} // This is for `asap.js` only.
// Its name will be periodically randomized to break any code that depends on
// its existence.


rawAsap.makeRequestCallFromTimer = makeRequestCallFromTimer; // ASAP was originally a nextTick shim included in Q. This was factored out
// into this ASAP package. It was later adapted to RSVP which made further
// amendments. These decisions, particularly to marginalize MessageChannel and
// to capture the MutationObserver implementation in a closure, were integrated
// back into ASAP proper.
// https://github.com/tildeio/rsvp.js/blob/cddf7232546a9cf858524b75cde6f9edf72620a7/lib/rsvp/asap.js

// RawTasks are recycled to reduce GC churn.

var freeTasks = []; // We queue errors to ensure they are thrown in right order (FIFO).
// Array-as-queue is good enough here, since we are just dealing with exceptions.

var pendingErrors = [];
var requestErrorThrow = rawAsap.makeRequestCallFromTimer(throwFirstError);

function throwFirstError() {
  if (pendingErrors.length) {
    throw pendingErrors.shift();
  }
}
/**
 * Calls a task as soon as possible after returning, in its own event, with priority
 * over other events like animation, reflow, and repaint. An error thrown from an
 * event will not interrupt, nor even substantially slow down the processing of
 * other events, but will be rather postponed to a lower priority event.
 * @param {{call}} task A callable object, typically a function that takes no
 * arguments.
 */


function asap(task) {
  var rawTask;

  if (freeTasks.length) {
    rawTask = freeTasks.pop();
  } else {
    rawTask = new RawTask();
  }

  rawTask.task = task;
  rawAsap(rawTask);
} // We wrap tasks with recyclable task objects.  A task object implements
// `call`, just like a function.

var RawTask =
/** @class */
function () {
  function RawTask() {}

  RawTask.prototype.call = function () {
    try {
      this.task.call();
    } catch (error) {
      if (asap.onerror) {
        // This hook exists purely for testing purposes.
        // Its name will be periodically randomized to break any code that
        // depends on its existence.
        asap.onerror(error);
      } else {
        // In a web browser, exceptions are not fatal. However, to avoid
        // slowing down the queue of pending tasks, we rethrow the error in a
        // lower priority turn.
        pendingErrors.push(error);
        requestErrorThrow();
      }
    } finally {
      this.task = null;
      freeTasks[freeTasks.length] = this;
    }
  };

  return RawTask;
}();

function _classCallCheck$5(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties$5(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass$5(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties$5(Constructor.prototype, protoProps); if (staticProps) _defineProperties$5(Constructor, staticProps); return Constructor; }

function _slicedToArray$7(arr, i) { return _arrayWithHoles$7(arr) || _iterableToArrayLimit$7(arr, i) || _unsupportedIterableToArray$7(arr, i) || _nonIterableRest$7(); }

function _nonIterableRest$7() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray$7(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray$7(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray$7(o, minLen); }

function _arrayLikeToArray$7(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit$7(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles$7(arr) { if (Array.isArray(arr)) return arr; }

function getNextHandlerId(role) {
  var id = getNextUniqueId().toString();

  switch (role) {
    case HandlerRole.SOURCE:
      return "S".concat(id);

    case HandlerRole.TARGET:
      return "T".concat(id);

    default:
      throw new Error("Unknown Handler Role: ".concat(role));
  }
}

function parseRoleFromHandlerId(handlerId) {
  switch (handlerId[0]) {
    case 'S':
      return HandlerRole.SOURCE;

    case 'T':
      return HandlerRole.TARGET;

    default:
      invariant(false, "Cannot parse handler ID: ".concat(handlerId));
  }
}

function mapContainsValue(map, searchValue) {
  var entries = map.entries();
  var isDone = false;

  do {
    var _entries$next = entries.next(),
        done = _entries$next.done,
        _entries$next$value = _slicedToArray$7(_entries$next.value, 2),
        value = _entries$next$value[1];

    if (value === searchValue) {
      return true;
    }

    isDone = !!done;
  } while (!isDone);

  return false;
}

var HandlerRegistryImpl = /*#__PURE__*/function () {
  function HandlerRegistryImpl(store) {
    _classCallCheck$5(this, HandlerRegistryImpl);

    this.types = new Map();
    this.dragSources = new Map();
    this.dropTargets = new Map();
    this.pinnedSourceId = null;
    this.pinnedSource = null;
    this.store = store;
  }

  _createClass$5(HandlerRegistryImpl, [{
    key: "addSource",
    value: function addSource$1(type, source) {
      validateType(type);
      validateSourceContract(source);
      var sourceId = this.addHandler(HandlerRole.SOURCE, type, source);
      this.store.dispatch(addSource(sourceId));
      return sourceId;
    }
  }, {
    key: "addTarget",
    value: function addTarget$1(type, target) {
      validateType(type, true);
      validateTargetContract(target);
      var targetId = this.addHandler(HandlerRole.TARGET, type, target);
      this.store.dispatch(addTarget(targetId));
      return targetId;
    }
  }, {
    key: "containsHandler",
    value: function containsHandler(handler) {
      return mapContainsValue(this.dragSources, handler) || mapContainsValue(this.dropTargets, handler);
    }
  }, {
    key: "getSource",
    value: function getSource(sourceId) {
      var includePinned = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
      invariant(this.isSourceId(sourceId), 'Expected a valid source ID.');
      var isPinned = includePinned && sourceId === this.pinnedSourceId;
      var source = isPinned ? this.pinnedSource : this.dragSources.get(sourceId);
      return source;
    }
  }, {
    key: "getTarget",
    value: function getTarget(targetId) {
      invariant(this.isTargetId(targetId), 'Expected a valid target ID.');
      return this.dropTargets.get(targetId);
    }
  }, {
    key: "getSourceType",
    value: function getSourceType(sourceId) {
      invariant(this.isSourceId(sourceId), 'Expected a valid source ID.');
      return this.types.get(sourceId);
    }
  }, {
    key: "getTargetType",
    value: function getTargetType(targetId) {
      invariant(this.isTargetId(targetId), 'Expected a valid target ID.');
      return this.types.get(targetId);
    }
  }, {
    key: "isSourceId",
    value: function isSourceId(handlerId) {
      var role = parseRoleFromHandlerId(handlerId);
      return role === HandlerRole.SOURCE;
    }
  }, {
    key: "isTargetId",
    value: function isTargetId(handlerId) {
      var role = parseRoleFromHandlerId(handlerId);
      return role === HandlerRole.TARGET;
    }
  }, {
    key: "removeSource",
    value: function removeSource$1(sourceId) {
      var _this = this;

      invariant(this.getSource(sourceId), 'Expected an existing source.');
      this.store.dispatch(removeSource(sourceId));
      asap(function () {
        _this.dragSources.delete(sourceId);

        _this.types.delete(sourceId);
      });
    }
  }, {
    key: "removeTarget",
    value: function removeTarget$1(targetId) {
      invariant(this.getTarget(targetId), 'Expected an existing target.');
      this.store.dispatch(removeTarget(targetId));
      this.dropTargets.delete(targetId);
      this.types.delete(targetId);
    }
  }, {
    key: "pinSource",
    value: function pinSource(sourceId) {
      var source = this.getSource(sourceId);
      invariant(source, 'Expected an existing source.');
      this.pinnedSourceId = sourceId;
      this.pinnedSource = source;
    }
  }, {
    key: "unpinSource",
    value: function unpinSource() {
      invariant(this.pinnedSource, 'No source is pinned at the time.');
      this.pinnedSourceId = null;
      this.pinnedSource = null;
    }
  }, {
    key: "addHandler",
    value: function addHandler(role, type, handler) {
      var id = getNextHandlerId(role);
      this.types.set(id, type);

      if (role === HandlerRole.SOURCE) {
        this.dragSources.set(id, handler);
      } else if (role === HandlerRole.TARGET) {
        this.dropTargets.set(id, handler);
      }

      return id;
    }
  }]);

  return HandlerRegistryImpl;
}();

function _classCallCheck$4(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties$4(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass$4(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties$4(Constructor.prototype, protoProps); if (staticProps) _defineProperties$4(Constructor, staticProps); return Constructor; }

function makeStoreInstance(debugMode) {
  // TODO: if we ever make a react-native version of this,
  // we'll need to consider how to pull off dev-tooling
  var reduxDevTools = typeof window !== 'undefined' && window.__REDUX_DEVTOOLS_EXTENSION__;
  return createStore(reduce, debugMode && reduxDevTools && reduxDevTools({
    name: 'dnd-core',
    instanceId: 'dnd-core'
  }));
}

var DragDropManagerImpl = /*#__PURE__*/function () {
  function DragDropManagerImpl() {
    var _this = this;

    var debugMode = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;

    _classCallCheck$4(this, DragDropManagerImpl);

    this.isSetUp = false;

    this.handleRefCountChange = function () {
      var shouldSetUp = _this.store.getState().refCount > 0;

      if (_this.backend) {
        if (shouldSetUp && !_this.isSetUp) {
          _this.backend.setup();

          _this.isSetUp = true;
        } else if (!shouldSetUp && _this.isSetUp) {
          _this.backend.teardown();

          _this.isSetUp = false;
        }
      }
    };

    var store = makeStoreInstance(debugMode);
    this.store = store;
    this.monitor = new DragDropMonitorImpl(store, new HandlerRegistryImpl(store));
    store.subscribe(this.handleRefCountChange);
  }

  _createClass$4(DragDropManagerImpl, [{
    key: "receiveBackend",
    value: function receiveBackend(backend) {
      this.backend = backend;
    }
  }, {
    key: "getMonitor",
    value: function getMonitor() {
      return this.monitor;
    }
  }, {
    key: "getBackend",
    value: function getBackend() {
      return this.backend;
    }
  }, {
    key: "getRegistry",
    value: function getRegistry() {
      return this.monitor.registry;
    }
  }, {
    key: "getActions",
    value: function getActions() {
      /* eslint-disable-next-line @typescript-eslint/no-this-alias */
      var manager = this;
      var dispatch = this.store.dispatch;

      function bindActionCreator(actionCreator) {
        return function () {
          for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
            args[_key] = arguments[_key];
          }

          var action = actionCreator.apply(manager, args);

          if (typeof action !== 'undefined') {
            dispatch(action);
          }
        };
      }

      var actions = createDragDropActions(this);
      return Object.keys(actions).reduce(function (boundActions, key) {
        var action = actions[key];
        boundActions[key] = bindActionCreator(action);
        return boundActions;
      }, {});
    }
  }, {
    key: "dispatch",
    value: function dispatch(action) {
      this.store.dispatch(action);
    }
  }]);

  return DragDropManagerImpl;
}();

function createDragDropManager(backendFactory, globalContext, backendOptions, debugMode) {
  var manager = new DragDropManagerImpl(debugMode);
  var backend = backendFactory(manager, globalContext, backendOptions);
  manager.receiveBackend(backend);
  return manager;
}

/**
 * Create the React Context
 */

var DndContext = react.createContext({
  dragDropManager: undefined
});
/**
 * Creates the context object we're providing
 * @param backend
 * @param context
 */

function createDndContext(backend, context, options, debugMode) {
  return {
    dragDropManager: createDragDropManager(backend, context, options, debugMode)
  };
}

function _slicedToArray$6(arr, i) { return _arrayWithHoles$6(arr) || _iterableToArrayLimit$6(arr, i) || _unsupportedIterableToArray$6(arr, i) || _nonIterableRest$6(); }

function _nonIterableRest$6() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray$6(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray$6(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray$6(o, minLen); }

function _arrayLikeToArray$6(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit$6(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles$6(arr) { if (Array.isArray(arr)) return arr; }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }
var refCount = 0;
/**
 * A React component that provides the React-DnD context
 */

var DndProvider = react.memo(function (_ref) {
  var children = _ref.children,
      props = _objectWithoutProperties(_ref, ["children"]);

  var _getDndContextValue = getDndContextValue(props),
      _getDndContextValue2 = _slicedToArray$6(_getDndContextValue, 2),
      manager = _getDndContextValue2[0],
      isGlobalInstance = _getDndContextValue2[1]; // memoized from props

  /**
   * If the global context was used to store the DND context
   * then where theres no more references to it we should
   * clean it up to avoid memory leaks
   */


  react.useEffect(function () {
    if (isGlobalInstance) {
      refCount++;
    }

    return function () {
      if (isGlobalInstance) {
        refCount--;

        if (refCount === 0) {
          var context = getGlobalContext();
          context[instanceSymbol] = null;
        }
      }
    };
  }, []);
  return react.createElement(DndContext.Provider, {
    value: manager
  }, children);
});
DndProvider.displayName = 'DndProvider';

function getDndContextValue(props) {
  if ('manager' in props) {
    var _manager = {
      dragDropManager: props.manager
    };
    return [_manager, false];
  }

  var manager = createSingletonDndContext(props.backend, props.context, props.options, props.debugMode);
  var isGlobalInstance = !props.context;
  return [manager, isGlobalInstance];
}

var instanceSymbol = Symbol.for('__REACT_DND_CONTEXT_INSTANCE__');

function createSingletonDndContext(backend) {
  var context = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : getGlobalContext();
  var options = arguments.length > 2 ? arguments[2] : undefined;
  var debugMode = arguments.length > 3 ? arguments[3] : undefined;
  var ctx = context;

  if (!ctx[instanceSymbol]) {
    ctx[instanceSymbol] = createDndContext(backend, context, options, debugMode);
  }

  return ctx[instanceSymbol];
}

function getGlobalContext() {
  return typeof global !== 'undefined' ? global : window;
}

var useIsomorphicLayoutEffect = typeof window !== 'undefined' ? react.useLayoutEffect : react.useEffect;

function shallowEqual(objA, objB, compare, compareContext) {
  var compareResult = compare ? compare.call(compareContext, objA, objB) : void 0;

  if (compareResult !== void 0) {
    return !!compareResult;
  }

  if (objA === objB) {
    return true;
  }

  if (typeof objA !== 'object' || !objA || typeof objB !== 'object' || !objB) {
    return false;
  }

  var keysA = Object.keys(objA);
  var keysB = Object.keys(objB);

  if (keysA.length !== keysB.length) {
    return false;
  }

  var bHasOwnProperty = Object.prototype.hasOwnProperty.bind(objB); // Test for A's keys different from B.

  for (var idx = 0; idx < keysA.length; idx++) {
    var key = keysA[idx];

    if (!bHasOwnProperty(key)) {
      return false;
    }

    var valueA = objA[key];
    var valueB = objB[key];
    compareResult = compare ? compare.call(compareContext, valueA, valueB, key) : void 0;

    if (compareResult === false || compareResult === void 0 && valueA !== valueB) {
      return false;
    }
  }

  return true;
}

function _slicedToArray$5(arr, i) { return _arrayWithHoles$5(arr) || _iterableToArrayLimit$5(arr, i) || _unsupportedIterableToArray$5(arr, i) || _nonIterableRest$5(); }

function _nonIterableRest$5() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray$5(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray$5(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray$5(o, minLen); }

function _arrayLikeToArray$5(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit$5(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles$5(arr) { if (Array.isArray(arr)) return arr; }
/**
 *
 * @param monitor The monitor to collect state from
 * @param collect The collecting function
 * @param onUpdate A method to invoke when updates occur
 */

function useCollector(monitor, collect, onUpdate) {
  var _useState = react.useState(function () {
    return collect(monitor);
  }),
      _useState2 = _slicedToArray$5(_useState, 2),
      collected = _useState2[0],
      setCollected = _useState2[1];

  var updateCollected = react.useCallback(function () {
    var nextValue = collect(monitor);

    if (!shallowEqual(collected, nextValue)) {
      setCollected(nextValue);

      if (onUpdate) {
        onUpdate();
      }
    }
  }, [collected, monitor, onUpdate]); // update the collected properties after the first render
  // and the components are attached to dnd-core

  useIsomorphicLayoutEffect(updateCollected, []);
  return [collected, updateCollected];
}

function _slicedToArray$4(arr, i) { return _arrayWithHoles$4(arr) || _iterableToArrayLimit$4(arr, i) || _unsupportedIterableToArray$4(arr, i) || _nonIterableRest$4(); }

function _nonIterableRest$4() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray$4(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray$4(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray$4(o, minLen); }

function _arrayLikeToArray$4(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit$4(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles$4(arr) { if (Array.isArray(arr)) return arr; }
function useMonitorOutput(monitor, collect, onCollect) {
  var _useCollector = useCollector(monitor, collect, onCollect),
      _useCollector2 = _slicedToArray$4(_useCollector, 2),
      collected = _useCollector2[0],
      updateCollected = _useCollector2[1];

  useIsomorphicLayoutEffect(function subscribeToMonitorStateChange() {
    var handlerId = monitor.getHandlerId();

    if (handlerId == null) {
      return undefined;
    }

    return monitor.subscribeToStateChange(updateCollected, {
      handlerIds: [handlerId]
    });
  }, [monitor, updateCollected]);
  return collected;
}

function registerTarget(type, target, manager) {
  var registry = manager.getRegistry();
  var targetId = registry.addTarget(type, target);
  return [targetId, function () {
    return registry.removeTarget(targetId);
  }];
}
function registerSource(type, source, manager) {
  var registry = manager.getRegistry();
  var sourceId = registry.addSource(type, source);
  return [sourceId, function () {
    return registry.removeSource(sourceId);
  }];
}

/**
 * A hook to retrieve the DragDropManager from Context
 */

function useDragDropManager() {
  var _useContext = react.useContext(DndContext),
      dragDropManager = _useContext.dragDropManager;

  invariant(dragDropManager != null, 'Expected drag drop context');
  return dragDropManager;
}

function _classCallCheck$3(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties$3(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass$3(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties$3(Constructor.prototype, protoProps); if (staticProps) _defineProperties$3(Constructor, staticProps); return Constructor; }
var isCallingCanDrag = false;
var isCallingIsDragging = false;
var DragSourceMonitorImpl = /*#__PURE__*/function () {
  function DragSourceMonitorImpl(manager) {
    _classCallCheck$3(this, DragSourceMonitorImpl);

    this.sourceId = null;
    this.internalMonitor = manager.getMonitor();
  }

  _createClass$3(DragSourceMonitorImpl, [{
    key: "receiveHandlerId",
    value: function receiveHandlerId(sourceId) {
      this.sourceId = sourceId;
    }
  }, {
    key: "getHandlerId",
    value: function getHandlerId() {
      return this.sourceId;
    }
  }, {
    key: "canDrag",
    value: function canDrag() {
      invariant(!isCallingCanDrag, 'You may not call monitor.canDrag() inside your canDrag() implementation. ' + 'Read more: http://react-dnd.github.io/react-dnd/docs/api/drag-source-monitor');

      try {
        isCallingCanDrag = true;
        return this.internalMonitor.canDragSource(this.sourceId);
      } finally {
        isCallingCanDrag = false;
      }
    }
  }, {
    key: "isDragging",
    value: function isDragging() {
      if (!this.sourceId) {
        return false;
      }

      invariant(!isCallingIsDragging, 'You may not call monitor.isDragging() inside your isDragging() implementation. ' + 'Read more: http://react-dnd.github.io/react-dnd/docs/api/drag-source-monitor');

      try {
        isCallingIsDragging = true;
        return this.internalMonitor.isDraggingSource(this.sourceId);
      } finally {
        isCallingIsDragging = false;
      }
    }
  }, {
    key: "subscribeToStateChange",
    value: function subscribeToStateChange(listener, options) {
      return this.internalMonitor.subscribeToStateChange(listener, options);
    }
  }, {
    key: "isDraggingSource",
    value: function isDraggingSource(sourceId) {
      return this.internalMonitor.isDraggingSource(sourceId);
    }
  }, {
    key: "isOverTarget",
    value: function isOverTarget(targetId, options) {
      return this.internalMonitor.isOverTarget(targetId, options);
    }
  }, {
    key: "getTargetIds",
    value: function getTargetIds() {
      return this.internalMonitor.getTargetIds();
    }
  }, {
    key: "isSourcePublic",
    value: function isSourcePublic() {
      return this.internalMonitor.isSourcePublic();
    }
  }, {
    key: "getSourceId",
    value: function getSourceId() {
      return this.internalMonitor.getSourceId();
    }
  }, {
    key: "subscribeToOffsetChange",
    value: function subscribeToOffsetChange(listener) {
      return this.internalMonitor.subscribeToOffsetChange(listener);
    }
  }, {
    key: "canDragSource",
    value: function canDragSource(sourceId) {
      return this.internalMonitor.canDragSource(sourceId);
    }
  }, {
    key: "canDropOnTarget",
    value: function canDropOnTarget(targetId) {
      return this.internalMonitor.canDropOnTarget(targetId);
    }
  }, {
    key: "getItemType",
    value: function getItemType() {
      return this.internalMonitor.getItemType();
    }
  }, {
    key: "getItem",
    value: function getItem() {
      return this.internalMonitor.getItem();
    }
  }, {
    key: "getDropResult",
    value: function getDropResult() {
      return this.internalMonitor.getDropResult();
    }
  }, {
    key: "didDrop",
    value: function didDrop() {
      return this.internalMonitor.didDrop();
    }
  }, {
    key: "getInitialClientOffset",
    value: function getInitialClientOffset() {
      return this.internalMonitor.getInitialClientOffset();
    }
  }, {
    key: "getInitialSourceClientOffset",
    value: function getInitialSourceClientOffset() {
      return this.internalMonitor.getInitialSourceClientOffset();
    }
  }, {
    key: "getSourceClientOffset",
    value: function getSourceClientOffset() {
      return this.internalMonitor.getSourceClientOffset();
    }
  }, {
    key: "getClientOffset",
    value: function getClientOffset() {
      return this.internalMonitor.getClientOffset();
    }
  }, {
    key: "getDifferenceFromInitialOffset",
    value: function getDifferenceFromInitialOffset() {
      return this.internalMonitor.getDifferenceFromInitialOffset();
    }
  }]);

  return DragSourceMonitorImpl;
}();

function setRef(ref, node) {
  if (typeof ref === 'function') {
    ref(node);
  } else {
    ref.current = node;
  }
}

function cloneWithRef(element, newRef) {
  var previousRef = element.ref;
  invariant(typeof previousRef !== 'string', 'Cannot connect React DnD to an element with an existing string ref. ' + 'Please convert it to use a callback ref instead, or wrap it into a <span> or <div>. ' + 'Read more: https://facebook.github.io/react/docs/more-about-refs.html#the-ref-callback-attribute');

  if (!previousRef) {
    // When there is no ref on the element, use the new ref directly
    return react.cloneElement(element, {
      ref: newRef
    });
  } else {
    return react.cloneElement(element, {
      ref: function ref(node) {
        setRef(previousRef, node);
        setRef(newRef, node);
      }
    });
  }
}

function throwIfCompositeComponentElement(element) {
  // Custom components can no longer be wrapped directly in React DnD 2.0
  // so that we don't need to depend on findDOMNode() from react-dom.
  if (typeof element.type === 'string') {
    return;
  }

  var displayName = element.type.displayName || element.type.name || 'the component';
  throw new Error('Only native element nodes can now be passed to React DnD connectors.' + "You can either wrap ".concat(displayName, " into a <div>, or turn it into a ") + 'drag source or a drop target itself.');
}

function wrapHookToRecognizeElement(hook) {
  return function () {
    var elementOrNode = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : null;
    var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;

    // When passed a node, call the hook straight away.
    if (!react.isValidElement(elementOrNode)) {
      var node = elementOrNode;
      hook(node, options); // return the node so it can be chained (e.g. when within callback refs
      // <div ref={node => connectDragSource(connectDropTarget(node))}/>

      return node;
    } // If passed a ReactElement, clone it and attach this function as a ref.
    // This helps us achieve a neat API where user doesn't even know that refs
    // are being used under the hood.


    var element = elementOrNode;
    throwIfCompositeComponentElement(element); // When no options are passed, use the hook directly

    var ref = options ? function (node) {
      return hook(node, options);
    } : hook;
    return cloneWithRef(element, ref);
  };
}

function wrapConnectorHooks(hooks) {
  var wrappedHooks = {};
  Object.keys(hooks).forEach(function (key) {
    var hook = hooks[key]; // ref objects should be passed straight through without wrapping

    if (key.endsWith('Ref')) {
      wrappedHooks[key] = hooks[key];
    } else {
      var wrappedHook = wrapHookToRecognizeElement(hook);

      wrappedHooks[key] = function () {
        return wrappedHook;
      };
    }
  });
  return wrappedHooks;
}

function _typeof$1(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof$1 = function _typeof(obj) { return typeof obj; }; } else { _typeof$1 = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof$1(obj); }

function isRef(obj) {
  return (// eslint-disable-next-line no-prototype-builtins
    obj !== null && _typeof$1(obj) === 'object' && Object.prototype.hasOwnProperty.call(obj, 'current')
  );
}

function _classCallCheck$2(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties$2(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass$2(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties$2(Constructor.prototype, protoProps); if (staticProps) _defineProperties$2(Constructor, staticProps); return Constructor; }
var SourceConnector = /*#__PURE__*/function () {
  function SourceConnector(backend) {
    var _this = this;

    _classCallCheck$2(this, SourceConnector);

    this.hooks = wrapConnectorHooks({
      dragSource: function dragSource(node, options) {
        _this.clearDragSource();

        _this.dragSourceOptions = options || null;

        if (isRef(node)) {
          _this.dragSourceRef = node;
        } else {
          _this.dragSourceNode = node;
        }

        _this.reconnectDragSource();
      },
      dragPreview: function dragPreview(node, options) {
        _this.clearDragPreview();

        _this.dragPreviewOptions = options || null;

        if (isRef(node)) {
          _this.dragPreviewRef = node;
        } else {
          _this.dragPreviewNode = node;
        }

        _this.reconnectDragPreview();
      }
    });
    this.handlerId = null; // The drop target may either be attached via ref or connect function

    this.dragSourceRef = null;
    this.dragSourceOptionsInternal = null; // The drag preview may either be attached via ref or connect function

    this.dragPreviewRef = null;
    this.dragPreviewOptionsInternal = null;
    this.lastConnectedHandlerId = null;
    this.lastConnectedDragSource = null;
    this.lastConnectedDragSourceOptions = null;
    this.lastConnectedDragPreview = null;
    this.lastConnectedDragPreviewOptions = null;
    this.backend = backend;
  }

  _createClass$2(SourceConnector, [{
    key: "receiveHandlerId",
    value: function receiveHandlerId(newHandlerId) {
      if (this.handlerId === newHandlerId) {
        return;
      }

      this.handlerId = newHandlerId;
      this.reconnect();
    }
  }, {
    key: "reconnect",
    value: function reconnect() {
      this.reconnectDragSource();
      this.reconnectDragPreview();
    }
  }, {
    key: "reconnectDragSource",
    value: function reconnectDragSource() {
      var dragSource = this.dragSource; // if nothing has changed then don't resubscribe

      var didChange = this.didHandlerIdChange() || this.didConnectedDragSourceChange() || this.didDragSourceOptionsChange();

      if (didChange) {
        this.disconnectDragSource();
      }

      if (!this.handlerId) {
        return;
      }

      if (!dragSource) {
        this.lastConnectedDragSource = dragSource;
        return;
      }

      if (didChange) {
        this.lastConnectedHandlerId = this.handlerId;
        this.lastConnectedDragSource = dragSource;
        this.lastConnectedDragSourceOptions = this.dragSourceOptions;
        this.dragSourceUnsubscribe = this.backend.connectDragSource(this.handlerId, dragSource, this.dragSourceOptions);
      }
    }
  }, {
    key: "reconnectDragPreview",
    value: function reconnectDragPreview() {
      var dragPreview = this.dragPreview; // if nothing has changed then don't resubscribe

      var didChange = this.didHandlerIdChange() || this.didConnectedDragPreviewChange() || this.didDragPreviewOptionsChange();

      if (didChange) {
        this.disconnectDragPreview();
      }

      if (!this.handlerId) {
        return;
      }

      if (!dragPreview) {
        this.lastConnectedDragPreview = dragPreview;
        return;
      }

      if (didChange) {
        this.lastConnectedHandlerId = this.handlerId;
        this.lastConnectedDragPreview = dragPreview;
        this.lastConnectedDragPreviewOptions = this.dragPreviewOptions;
        this.dragPreviewUnsubscribe = this.backend.connectDragPreview(this.handlerId, dragPreview, this.dragPreviewOptions);
      }
    }
  }, {
    key: "didHandlerIdChange",
    value: function didHandlerIdChange() {
      return this.lastConnectedHandlerId !== this.handlerId;
    }
  }, {
    key: "didConnectedDragSourceChange",
    value: function didConnectedDragSourceChange() {
      return this.lastConnectedDragSource !== this.dragSource;
    }
  }, {
    key: "didConnectedDragPreviewChange",
    value: function didConnectedDragPreviewChange() {
      return this.lastConnectedDragPreview !== this.dragPreview;
    }
  }, {
    key: "didDragSourceOptionsChange",
    value: function didDragSourceOptionsChange() {
      return !shallowEqual(this.lastConnectedDragSourceOptions, this.dragSourceOptions);
    }
  }, {
    key: "didDragPreviewOptionsChange",
    value: function didDragPreviewOptionsChange() {
      return !shallowEqual(this.lastConnectedDragPreviewOptions, this.dragPreviewOptions);
    }
  }, {
    key: "disconnectDragSource",
    value: function disconnectDragSource() {
      if (this.dragSourceUnsubscribe) {
        this.dragSourceUnsubscribe();
        this.dragSourceUnsubscribe = undefined;
      }
    }
  }, {
    key: "disconnectDragPreview",
    value: function disconnectDragPreview() {
      if (this.dragPreviewUnsubscribe) {
        this.dragPreviewUnsubscribe();
        this.dragPreviewUnsubscribe = undefined;
        this.dragPreviewNode = null;
        this.dragPreviewRef = null;
      }
    }
  }, {
    key: "clearDragSource",
    value: function clearDragSource() {
      this.dragSourceNode = null;
      this.dragSourceRef = null;
    }
  }, {
    key: "clearDragPreview",
    value: function clearDragPreview() {
      this.dragPreviewNode = null;
      this.dragPreviewRef = null;
    }
  }, {
    key: "connectTarget",
    get: function get() {
      return this.dragSource;
    }
  }, {
    key: "dragSourceOptions",
    get: function get() {
      return this.dragSourceOptionsInternal;
    },
    set: function set(options) {
      this.dragSourceOptionsInternal = options;
    }
  }, {
    key: "dragPreviewOptions",
    get: function get() {
      return this.dragPreviewOptionsInternal;
    },
    set: function set(options) {
      this.dragPreviewOptionsInternal = options;
    }
  }, {
    key: "dragSource",
    get: function get() {
      return this.dragSourceNode || this.dragSourceRef && this.dragSourceRef.current;
    }
  }, {
    key: "dragPreview",
    get: function get() {
      return this.dragPreviewNode || this.dragPreviewRef && this.dragPreviewRef.current;
    }
  }]);

  return SourceConnector;
}();

function _slicedToArray$3(arr, i) { return _arrayWithHoles$3(arr) || _iterableToArrayLimit$3(arr, i) || _unsupportedIterableToArray$3(arr, i) || _nonIterableRest$3(); }

function _nonIterableRest$3() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray$3(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray$3(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray$3(o, minLen); }

function _arrayLikeToArray$3(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit$3(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles$3(arr) { if (Array.isArray(arr)) return arr; }

function _typeof(obj) { "@babel/helpers - typeof"; if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }
function useDragSourceMonitor() {
  var manager = useDragDropManager();
  var monitor = react.useMemo(function () {
    return new DragSourceMonitorImpl(manager);
  }, [manager]);
  var connector = react.useMemo(function () {
    return new SourceConnector(manager.getBackend());
  }, [manager]);
  return [monitor, connector];
}
function useDragHandler(spec, monitor, connector) {
  var manager = useDragDropManager();
  var handler = react.useMemo(function () {
    return {
      beginDrag: function beginDrag() {
        var _spec$current = spec.current,
            begin = _spec$current.begin,
            item = _spec$current.item;

        if (begin) {
          var beginResult = begin(monitor);
          invariant(beginResult == null || _typeof(beginResult) === 'object', 'dragSpec.begin() must either return an object, undefined, or null');
          return beginResult || item || {};
        }

        return item || {};
      },
      canDrag: function canDrag() {
        if (typeof spec.current.canDrag === 'boolean') {
          return spec.current.canDrag;
        } else if (typeof spec.current.canDrag === 'function') {
          return spec.current.canDrag(monitor);
        } else {
          return true;
        }
      },
      isDragging: function isDragging(globalMonitor, target) {
        var isDragging = spec.current.isDragging;
        return isDragging ? isDragging(monitor) : target === globalMonitor.getSourceId();
      },
      endDrag: function endDrag() {
        var end = spec.current.end;

        if (end) {
          end(monitor.getItem(), monitor);
        }

        connector.reconnect();
      }
    };
  }, []);
  useIsomorphicLayoutEffect(function registerHandler() {
    var _registerSource = registerSource(spec.current.item.type, handler, manager),
        _registerSource2 = _slicedToArray$3(_registerSource, 2),
        handlerId = _registerSource2[0],
        unregister = _registerSource2[1];

    monitor.receiveHandlerId(handlerId);
    connector.receiveHandlerId(handlerId);
    return unregister;
  }, []);
}

function _slicedToArray$2(arr, i) { return _arrayWithHoles$2(arr) || _iterableToArrayLimit$2(arr, i) || _unsupportedIterableToArray$2(arr, i) || _nonIterableRest$2(); }

function _nonIterableRest$2() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray$2(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray$2(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray$2(o, minLen); }

function _arrayLikeToArray$2(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit$2(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles$2(arr) { if (Array.isArray(arr)) return arr; }
/**
 * useDragSource hook
 * @param sourceSpec The drag source specification *
 */

function useDrag(spec) {
  var specRef = react.useRef(spec);
  specRef.current = spec; // TODO: wire options into createSourceConnector

  invariant(spec.item != null, 'item must be defined');
  invariant(spec.item.type != null, 'item type must be defined');

  var _useDragSourceMonitor = useDragSourceMonitor(),
      _useDragSourceMonitor2 = _slicedToArray$2(_useDragSourceMonitor, 2),
      monitor = _useDragSourceMonitor2[0],
      connector = _useDragSourceMonitor2[1];

  useDragHandler(specRef, monitor, connector);
  var result = useMonitorOutput(monitor, specRef.current.collect || function () {
    return {};
  }, function () {
    return connector.reconnect();
  });
  var connectDragSource = react.useMemo(function () {
    return connector.hooks.dragSource();
  }, [connector]);
  var connectDragPreview = react.useMemo(function () {
    return connector.hooks.dragPreview();
  }, [connector]);
  useIsomorphicLayoutEffect(function () {
    connector.dragSourceOptions = specRef.current.options || null;
    connector.reconnect();
  }, [connector]);
  useIsomorphicLayoutEffect(function () {
    connector.dragPreviewOptions = specRef.current.previewOptions || null;
    connector.reconnect();
  }, [connector]);
  return [result, connectDragSource, connectDragPreview];
}

function _classCallCheck$1(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties$1(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass$1(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties$1(Constructor.prototype, protoProps); if (staticProps) _defineProperties$1(Constructor, staticProps); return Constructor; }
var TargetConnector = /*#__PURE__*/function () {
  function TargetConnector(backend) {
    var _this = this;

    _classCallCheck$1(this, TargetConnector);

    this.hooks = wrapConnectorHooks({
      dropTarget: function dropTarget(node, options) {
        _this.clearDropTarget();

        _this.dropTargetOptions = options;

        if (isRef(node)) {
          _this.dropTargetRef = node;
        } else {
          _this.dropTargetNode = node;
        }

        _this.reconnect();
      }
    });
    this.handlerId = null; // The drop target may either be attached via ref or connect function

    this.dropTargetRef = null;
    this.dropTargetOptionsInternal = null;
    this.lastConnectedHandlerId = null;
    this.lastConnectedDropTarget = null;
    this.lastConnectedDropTargetOptions = null;
    this.backend = backend;
  }

  _createClass$1(TargetConnector, [{
    key: "reconnect",
    value: function reconnect() {
      // if nothing has changed then don't resubscribe
      var didChange = this.didHandlerIdChange() || this.didDropTargetChange() || this.didOptionsChange();

      if (didChange) {
        this.disconnectDropTarget();
      }

      var dropTarget = this.dropTarget;

      if (!this.handlerId) {
        return;
      }

      if (!dropTarget) {
        this.lastConnectedDropTarget = dropTarget;
        return;
      }

      if (didChange) {
        this.lastConnectedHandlerId = this.handlerId;
        this.lastConnectedDropTarget = dropTarget;
        this.lastConnectedDropTargetOptions = this.dropTargetOptions;
        this.unsubscribeDropTarget = this.backend.connectDropTarget(this.handlerId, dropTarget, this.dropTargetOptions);
      }
    }
  }, {
    key: "receiveHandlerId",
    value: function receiveHandlerId(newHandlerId) {
      if (newHandlerId === this.handlerId) {
        return;
      }

      this.handlerId = newHandlerId;
      this.reconnect();
    }
  }, {
    key: "didHandlerIdChange",
    value: function didHandlerIdChange() {
      return this.lastConnectedHandlerId !== this.handlerId;
    }
  }, {
    key: "didDropTargetChange",
    value: function didDropTargetChange() {
      return this.lastConnectedDropTarget !== this.dropTarget;
    }
  }, {
    key: "didOptionsChange",
    value: function didOptionsChange() {
      return !shallowEqual(this.lastConnectedDropTargetOptions, this.dropTargetOptions);
    }
  }, {
    key: "disconnectDropTarget",
    value: function disconnectDropTarget() {
      if (this.unsubscribeDropTarget) {
        this.unsubscribeDropTarget();
        this.unsubscribeDropTarget = undefined;
      }
    }
  }, {
    key: "clearDropTarget",
    value: function clearDropTarget() {
      this.dropTargetRef = null;
      this.dropTargetNode = null;
    }
  }, {
    key: "connectTarget",
    get: function get() {
      return this.dropTarget;
    }
  }, {
    key: "dropTargetOptions",
    get: function get() {
      return this.dropTargetOptionsInternal;
    },
    set: function set(options) {
      this.dropTargetOptionsInternal = options;
    }
  }, {
    key: "dropTarget",
    get: function get() {
      return this.dropTargetNode || this.dropTargetRef && this.dropTargetRef.current;
    }
  }]);

  return TargetConnector;
}();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); return Constructor; }
var isCallingCanDrop = false;
var DropTargetMonitorImpl = /*#__PURE__*/function () {
  function DropTargetMonitorImpl(manager) {
    _classCallCheck(this, DropTargetMonitorImpl);

    this.targetId = null;
    this.internalMonitor = manager.getMonitor();
  }

  _createClass(DropTargetMonitorImpl, [{
    key: "receiveHandlerId",
    value: function receiveHandlerId(targetId) {
      this.targetId = targetId;
    }
  }, {
    key: "getHandlerId",
    value: function getHandlerId() {
      return this.targetId;
    }
  }, {
    key: "subscribeToStateChange",
    value: function subscribeToStateChange(listener, options) {
      return this.internalMonitor.subscribeToStateChange(listener, options);
    }
  }, {
    key: "canDrop",
    value: function canDrop() {
      // Cut out early if the target id has not been set. This should prevent errors
      // where the user has an older version of dnd-core like in
      // https://github.com/react-dnd/react-dnd/issues/1310
      if (!this.targetId) {
        return false;
      }

      invariant(!isCallingCanDrop, 'You may not call monitor.canDrop() inside your canDrop() implementation. ' + 'Read more: http://react-dnd.github.io/react-dnd/docs/api/drop-target-monitor');

      try {
        isCallingCanDrop = true;
        return this.internalMonitor.canDropOnTarget(this.targetId);
      } finally {
        isCallingCanDrop = false;
      }
    }
  }, {
    key: "isOver",
    value: function isOver(options) {
      if (!this.targetId) {
        return false;
      }

      return this.internalMonitor.isOverTarget(this.targetId, options);
    }
  }, {
    key: "getItemType",
    value: function getItemType() {
      return this.internalMonitor.getItemType();
    }
  }, {
    key: "getItem",
    value: function getItem() {
      return this.internalMonitor.getItem();
    }
  }, {
    key: "getDropResult",
    value: function getDropResult() {
      return this.internalMonitor.getDropResult();
    }
  }, {
    key: "didDrop",
    value: function didDrop() {
      return this.internalMonitor.didDrop();
    }
  }, {
    key: "getInitialClientOffset",
    value: function getInitialClientOffset() {
      return this.internalMonitor.getInitialClientOffset();
    }
  }, {
    key: "getInitialSourceClientOffset",
    value: function getInitialSourceClientOffset() {
      return this.internalMonitor.getInitialSourceClientOffset();
    }
  }, {
    key: "getSourceClientOffset",
    value: function getSourceClientOffset() {
      return this.internalMonitor.getSourceClientOffset();
    }
  }, {
    key: "getClientOffset",
    value: function getClientOffset() {
      return this.internalMonitor.getClientOffset();
    }
  }, {
    key: "getDifferenceFromInitialOffset",
    value: function getDifferenceFromInitialOffset() {
      return this.internalMonitor.getDifferenceFromInitialOffset();
    }
  }]);

  return DropTargetMonitorImpl;
}();

function _slicedToArray$1(arr, i) { return _arrayWithHoles$1(arr) || _iterableToArrayLimit$1(arr, i) || _unsupportedIterableToArray$1(arr, i) || _nonIterableRest$1(); }

function _nonIterableRest$1() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray$1(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray$1(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray$1(o, minLen); }

function _arrayLikeToArray$1(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit$1(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles$1(arr) { if (Array.isArray(arr)) return arr; }
function useDropTargetMonitor() {
  var manager = useDragDropManager();
  var monitor = react.useMemo(function () {
    return new DropTargetMonitorImpl(manager);
  }, [manager]);
  var connector = react.useMemo(function () {
    return new TargetConnector(manager.getBackend());
  }, [manager]);
  return [monitor, connector];
}
function useDropHandler(spec, monitor, connector) {
  var manager = useDragDropManager();
  var handler = react.useMemo(function () {
    return {
      canDrop: function canDrop() {
        var canDrop = spec.current.canDrop;
        return canDrop ? canDrop(monitor.getItem(), monitor) : true;
      },
      hover: function hover() {
        var hover = spec.current.hover;

        if (hover) {
          hover(monitor.getItem(), monitor);
        }
      },
      drop: function drop() {
        var drop = spec.current.drop;

        if (drop) {
          return drop(monitor.getItem(), monitor);
        }
      }
    };
  }, [monitor]);
  useIsomorphicLayoutEffect(function registerHandler() {
    var _registerTarget = registerTarget(spec.current.accept, handler, manager),
        _registerTarget2 = _slicedToArray$1(_registerTarget, 2),
        handlerId = _registerTarget2[0],
        unregister = _registerTarget2[1];

    monitor.receiveHandlerId(handlerId);
    connector.receiveHandlerId(handlerId);
    return unregister;
  }, [monitor, connector]);
}

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { if (typeof Symbol === "undefined" || !(Symbol.iterator in Object(arr))) return; var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }
/**
 * useDropTarget Hook
 * @param spec The drop target specification
 */

function useDrop(spec) {
  var specRef = react.useRef(spec);
  specRef.current = spec;
  invariant(spec.accept != null, 'accept must be defined');

  var _useDropTargetMonitor = useDropTargetMonitor(),
      _useDropTargetMonitor2 = _slicedToArray(_useDropTargetMonitor, 2),
      monitor = _useDropTargetMonitor2[0],
      connector = _useDropTargetMonitor2[1];

  useDropHandler(specRef, monitor, connector);
  var result = useMonitorOutput(monitor, specRef.current.collect || function () {
    return {};
  }, function () {
    return connector.reconnect();
  });
  var connectDropTarget = react.useMemo(function () {
    return connector.hooks.dropTarget();
  }, [connector]);
  useIsomorphicLayoutEffect(function () {
    connector.dropTargetOptions = spec.options || null;
    connector.reconnect();
  }, [spec.options]);
  return [result, connectDropTarget];
}

export { DndProvider, useDrag, useDrop };
