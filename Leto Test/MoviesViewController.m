//
//  MoviesViewController.m
//  Leto Test
//
//  Created by Radoo on 03/02/15.
//  Copyright (c) 2015 Radoo. All rights reserved.
//

#import "MoviesViewController.h"
#import "MovieCustomCell.h"
#import "Constants.h"
#import "UIImageView+WebCache.h"

#define FILTER_STOP_WORDS YES

typedef enum
{
    TITLE_SORT,
    SCORE_SORT
} SORT_METHOD;

@interface MoviesViewController ()

@property (nonatomic, strong) NSArray *tableDataArray;
@property (nonatomic, assign) SORT_METHOD sortingMethod;

@end

@implementation MoviesViewController

#pragma mark - View Controller Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sortingMethod = TITLE_SORT;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Fetching Data Methods
- (void)fetchedMoviesData:(NSData *)responseData
{
    if (!responseData)
    {
        NSLog(@"Empty data");
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    
    if (error)
    {
        NSLog(@"Error occured while fetching films data: %@", error.description);
        self.tableDataArray = nil;
    }
    else
    {
        self.tableDataArray = [json objectForKey:@"movies"];
        [self sortTableData];
    }
    
    [self.filmsTableView reloadData];
}

- (void) sortTableData
{
    switch (self.sortingMethod)
    {
        case TITLE_SORT:
            [self sortFilmsByTitle];
            break;
        case SCORE_SORT:
            [self sortFilmsByRating];
            break;
        default:
            break;
    }
}

- (void) sortFilmsByTitle
{
    if (FILTER_STOP_WORDS)
    {
        NSMutableArray *auxMutableArray = [NSMutableArray new];
        NSSet *stopWords = [NSSet setWithObjects:@"an", @"are", @"as", @"at", @"be", @"by", @"for", @"from", @"how", @"in", @"is", @"it", @"of", @"on", @"or", @"that", @"the", @"this", @"to", @"what", @"when", @"where", @"who", @"will", @"with", nil];
        
        for (NSDictionary *dict in self.tableDataArray)
        {
            NSMutableDictionary *auxDict = [NSMutableDictionary dictionaryWithDictionary:dict];
            
            NSString *formattedString = nil;
            NSArray *words = [dict[@"title"] componentsSeparatedByString:@" "];
            for (NSString *word in words)
            {
                if (![stopWords containsObject:word.lowercaseString])
                {
                    if (!formattedString)
                    {
                        //Initialize formatted string
                        formattedString = word;
                    }
                    else
                    {
                        //append to the formatted string
                        formattedString = [NSString stringWithFormat:@"%@ %@", formattedString, word];
                    }
                }
            }
            
            auxDict[@"titleWithoutStopWords"] = formattedString;
            [auxMutableArray addObject:auxDict];
        }
        
        NSArray *auxArray = [NSArray arrayWithArray:auxMutableArray];
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"titleWithoutStopWords" ascending:YES];
        auxArray = [auxArray sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
        self.tableDataArray = auxArray;
    }
    else
    {
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
        self.tableDataArray = [self.tableDataArray sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    }
}

- (void) sortFilmsByRating
{
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"ratings.audience_score" ascending:NO];
    self.tableDataArray = [self.tableDataArray sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
}

- (void) searchFilmNamed:(NSString*) filmTitle
{
    if (!filmTitle || filmTitle.length == 0)
    {
        NSLog(@"Film title is empty");
        self.tableDataArray = nil;
        [self.filmsTableView reloadData];
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSString *requestURL = [NSString stringWithFormat:@"http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=%@&q=%@",API_KEY,filmTitle];
    NSString *validURLString = [requestURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(backgroundQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:validURLString]];
        [self performSelectorOnMainThread:@selector(fetchedMoviesData:) withObject:data waitUntilDone:YES];
    });
}

- (void) fetchNewFilms
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSString *requestURL = [NSString stringWithFormat:@"http://api.rottentomatoes.com/api/public/v1.0/lists/movies/opening.json?apikey=%@",API_KEY];
    NSString *validURLString = [requestURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(backgroundQueue, ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:validURLString]];
        [self performSelectorOnMainThread:@selector(fetchedMoviesData:) withObject:data waitUntilDone:YES];
    });
}

#pragma mark - UI Controls Actions
- (IBAction)sortButtonPressed:(id)sender
{
    NSMutableString *titleSortString = [NSMutableString stringWithString:@"Sort by title"];
    NSMutableString *scoreSortString = [NSMutableString stringWithString:@"Sort by score"];
    
    switch (self.sortingMethod)
    {
        case TITLE_SORT:
            [titleSortString appendString:@" ✓"];
            break;
        case SCORE_SORT:
            [scoreSortString appendString:@" ✓"];
            break;
        default:
            break;
    }
    
    UIActionSheet *sortActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select sorting method" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:titleSortString,scoreSortString,nil];
    
    [sortActionSheet showInView:self.view];
}

- (IBAction)segmentValueChanged:(UISegmentedControl*)sender
{
    NSInteger selectedIndex = sender.selectedSegmentIndex;
    
    switch (selectedIndex)
    {
        case 0: //Search Film
            [self showSearchBar];
            break;
        case 1: //New Films
            [self showNewFilms];
            break;
        default:
            break;
    }
}

- (void) showSearchBar
{
    self.openingFilmsLabel.hidden = YES;
    self.filmSearchBar.hidden = NO;
    
    [self searchFilmNamed:self.filmSearchBar.text];
}

- (void) showNewFilms
{
    self.openingFilmsLabel.hidden = NO;
    self.filmSearchBar.hidden = YES;
    
    [self fetchNewFilms];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableDataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MovieCell";
    
    MovieCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"MovieCustomCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    NSDictionary *filmDictionary = [self.tableDataArray objectAtIndex:indexPath.row];
    NSDictionary *postersDict = filmDictionary[@"posters"];
    
    cell.filmThumbnail.image = [UIImage imageNamed:@"placeholder.png"];
    
    if (postersDict)
    {
        NSString *imageURLString = postersDict[@"thumbnail"];
        
        if (imageURLString && ![imageURLString isEqual:[NSNull null]])
        {
            NSURL *imageURL = [NSURL URLWithString:imageURLString];
            [cell.filmThumbnail sd_setImageWithURL:imageURL placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
        }
    }
    
    NSString *filmTitle = filmDictionary[@"title"];
    if (!filmTitle) filmTitle = @"Unknown title";
    cell.filmTitleLabel.text = filmTitle;
    
    NSString *yearString = filmDictionary[@"year"];
    if (!yearString)
    {
        yearString = @"Unknown year";
    }
    else
    {
        yearString = [NSString stringWithFormat:@"Year: %@",yearString];
    }
    cell.filmYearLabel.text = yearString;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)])
    {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)])
    {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)])
    {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - Table view delegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISearchBarDelegate Methods
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self searchFilmNamed:searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark - UIActionSheetDelegate Methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case 0:  //sort by title
            self.sortingMethod = TITLE_SORT;
            break;
        case 1:  //sort by score
            self.sortingMethod = SCORE_SORT;
            break;
        case 2: //cancel
            return;
            break;
        default:
            break;
    }
    
    [self sortTableData];
    [self.filmsTableView reloadData];
}

@end
